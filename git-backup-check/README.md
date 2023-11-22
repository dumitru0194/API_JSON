
├── ansible.cfg
├── logs
├── playbooks
│   ├── remote-git-data-collection.yml
│   └── roles
│       ├── debug
│       │   └── tasks
│       │       └── main.yml
│       ├── git_config_collect
│       │   ├── files
│       │   │   ├── git_status_nice.json
│       │   │   ├── git_status_nice.json.bkup
│       │   │   └── result_final.json
│       │   ├── handlers
│       │   │   └── git_status_nice.json.parser.py
│       │   ├── tasks
│       │   │   ├── collect_data.yml
│       │   │   ├── main.yml
│       │   │   └── result_file.yml
│       │   ├── templates
│       │   └── vars
│       │       └── main.yml
│       └── git_config_web
│           ├── files
│           ├── handlers
│           │   └── api_ifbackup.sh
│           ├── tasks
│           │   └── main.yml
│           ├── templates
│           └── vars
└── README.md



Usage:

ansible-playbook ./playbooks/remote-git-data-collection.yml

Роль git_config_web собирает данные по серверам и GIT api используя скрипт.
Внутри ней формируется динамический инвентарь, который далее перепаётся роли git_config_collect

Результат работы без предобработки сохраняется в файл files/git_status_nice.json.bkup.
Файл git_status_nice.json  является готовым json файлом, который соединяется с файлом git3_custom_all.json из результатов первой роли.

Финальным результатом работы является выходной файл 
	playbooks/roles/git_config_collect/files/result_final.json

Пример хоста, к которому нет доступа:

  {
    "Hosts": "ir-rightel-rbt-dmz-01",
    "Repository_Size": "10MB",
    "last_activity": "2023-08-12",
    "Host exists": "yes",
    "Backup Description": "",
    "Ignore": "unreachable",
    "Backup": "unreachable"
  }

Пример хоста, к корому доступ есть, но нет вывода команд

  {
    "Hosts": "ir-rightel-rbt-dmz-01",
    "Repository_Size": "10MB",
    "last_activity": "2023-08-12",
    "Host exists": "yes",
    "Backup Description": "",
    "Ignore": "NULL",
    "Backup": "NULL"
  }

Пример хоста, в котором есть коррекртрный ответ

  {
    "Hosts": "tj-beeline-sms-bulk-01",
    "Repository_Size": "6MB",
    "last_activity": "2023-11-19",
    "Host exists": "yes",
    "Backup Description": "",
    "Ignore": "/etc/webmin/\n/etc/KANNEL/bin/\n/etc/KANNEL/include/\n/etc/KANNEL/lib/\n/etc/KANNEL/sbin/\n/etc/KANNEL/share/\n/etc/selinux/targeted/\n/etc/udev/\n/www/ussd/vendor/",
    "Backup": "/SCRIPTS/\n/etc/\n/usr/local/nagios/\n/var/spool/cron/\n/var/www/"
  }
