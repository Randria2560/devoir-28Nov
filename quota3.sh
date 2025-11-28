#!/bin/bash
# =========================================================
# Script quotas disque + inode sur 2 partitions
# Avec vérification fstab + cron + mail
# =========================================================

# ================================
# Points de montage
mkdir -p /data /mnt/data1
PARTITION1="/data"
PARTITION2="/mnt/data1"

# ====================================================
# Limites quotas
SOFT1=$((500*1024))   # 500 MB
HARD1=$((700*1024))   # 700 MB

INODE_SOFT=5000
INODE_HARD=7000

SCRIPT_PATH="/home/natacha/NATACHA/lecon programmation/script/$(basename "$0")"

# =============================================================
# Fonction : ajouter les partitions au fstab proprement
montage_partition(){

    echo "[INFO] Vérification /etc/fstab..."

    if ! grep -q "^/dev/sda4[[:space:]]\+$PARTITION1" /etc/fstab; then
        echo "/dev/sda4   $PARTITION1   ext4   defaults,usrquota   0 2" >> /etc/fstab
        echo "[OK] /dev/sda4 ajouté dans /etc/fstab."
    else
        echo "[SKIP] /dev/sda4 déjà présent dans /etc/fstab."
    fi

    if ! grep -q "^/dev/sda5[[:space:]]\+$PARTITION2" /etc/fstab; then
        echo "/dev/sda5   $PARTITION2   ext4   defaults,usrquota,grpquota   0 2" >> /etc/fstab
        echo "[OK] /dev/sda5 ajouté dans /etc/fstab."
    else
        echo "[SKIP] /dev/sda5 déjà présent dans /etc/fstab."
    fi
}

# ==========================================================
remount(){
    systemctl daemon-reload
    mount -o remount "$PARTITION1"
    mount -o remount "$PARTITION2"
    echo "[OK] Partitions remontées."
}

# =============================================================
config(){
    quotacheck -cum "$PARTITION1"
    quotacheck -cgum "$PARTITION2"
    echo "[OK] Fichiers de quotas générés."
}

# =================================================================
activation(){
    quotaon "$PARTITION1"
    quotaon "$PARTITION2"
    echo "[OK] Quotas activés."
}

# =====================================================================
application_quota(){
    echo "[INFO] Application des quotas utilisateurs..."

    for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
        
        setquota -u "$user" $SOFT1 $HARD1 0 0 "$PARTITION1"
        setquota -u "$user" 0 0 $INODE_SOFT $INODE_HARD "$PARTITION2"

        echo "  -> Quotas appliqués à $user"
    done

    echo "[INFO] Application quotas groupes..."
    for group in $(awk -F: '$3 >= 1000 {print $1}' /etc/group); do
        setquota -g "$group" 0 0 $INODE_SOFT $INODE_HARD "$PARTITION2"
        echo "  -> Groupe $group OK"
    done

    echo "[OK] Tous les quotas appliqués."
}

#================================================================================
cron(){
    CRONLINE="0 12 * * 1 $SCRIPT_PATH"

    if crontab -l 2>/dev/null | grep -Fxq "$CRONLINE"; then
        echo "[SKIP] Cron hebdomadaire déjà présent."
    else
        (crontab -l 2>/dev/null; echo "$CRONLINE") | crontab -
        echo "[OK] Cron hebdomadaire ajouté (lundi 12h)."
    fi
}

#==================================================================================
rapport(){
    echo "=== RAPPORT PARTITION $PARTITION1 ==="
    repquota -u "$PARTITION1"

    echo "=== RAPPORT PARTITION $PARTITION2 ==="
    repquota -gu "$PARTITION2"
}

#========================================================================================
cron_date(){

    CRONLINE="0 8 * * * $SCRIPT_PATH"

    if crontab -l 2>/dev/null | grep -Fxq "$CRONLINE"; then
        echo "[SKIP] Cron quotidien déjà présent."
    else
        (crontab -l 2>/dev/null; echo "$CRONLINE") | crontab -
        echo "[OK] Cron quotidien ajouté (tous les jours à 8h)."
    fi
}

#===================================================================================
mail(){
    for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)
    do
        QUOTA=$(quota -u "$user" | awk 'NR==3 {print $2}' | tr -d '*')
	SOFT_LIMIT=$(quota -u "$user" | awk 'NR==3 {print $3}' | tr -d '*')

        if [ -n "$QUOTA" ] && [ -n "$SOFT_LIMIT" ] && [ "$QUOTA" -ge "$SOFT_LIMIT" ]; then

            cron_date   # Ajout du cron journalier (si pas encore ajouté)

            MESSAGE="Alerte :

L'utilisateur $user a dépassé son quota.

Quota utilisé : $QUOTA KB
Limite : $SOFT_LIMIT KB

Message automatique."

            echo "$MESSAGE" | mail -s "Alerte quota : $user" "$user"

            echo "[MAIL] Alerte envoyée à $user"
        fi
    done
}

# ===================================================================================
# Exécution
montage_partition
remount
config
activation
application_quota
cron
rapport
mail

quotaoff $PARTITION1
quotaoff $PARTITION2

