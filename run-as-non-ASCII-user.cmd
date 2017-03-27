chcp 65001
net user "илья" password@12 /add
net localgroup administrators илья /add
psexec \\localhost -u илья -p password@12 -accepteula ping google.com
