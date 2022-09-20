mkdir /soft
cp /vagrant/orcl_software/* /soft
cd /soft
chmod +x /soft/OracleShellInstall.sh

## configure rac install shell
cat <<EOF>/soft/rac_install.sh
./OracleShellInstall.sh -i $NODE1_PUBLIC_IP `#Public ip`\
-n $PREFIX_NAME `# hostname`\
-rs oracle `# root password`\
-op oracle `# oracle password`\
-gp oracle `# grid password`\
-b /u01/app `# install basedir`\
-o $DB_NAME `# oraclesid`\
-s AL32UTF8 `# characterset`\
-pb1 $NODE1_PUBLIC_IP -pb2 $NODE2_PUBLIC_IP `# node public ip`\
-vi1 $NODE1_VIP_IP -vi2 $NODE2_VIP_IP `# node virtual ip`\
-pi1 $NODE1_PRIV_IP -pi2 $NODE2_PRIV_IP `# node private ip`\
-puf eth1 -prf eth2 `# network fcname`\
-si $SCAN_IP1 `# scan ip`\
-dd /dev/sdc `# asm data disk`\
-od /dev/sdb `# asm ocr disk`\
-or $OCR_REDUN `# asm ocr redundancy`\
-dr $DATA_REDUN `# asm data redundancy`\
-on OCR `# asm ocr diskgroupname`\
-dn DATA `# asm data diskgroupname`\
-gpa $Grid_PATCH \
-installmode rac \
-dbv $DB_VERSION \
-vbox $VIRTUALBOX \
-iso N
EOF