# ISPConfig helpers. They are quiet on systems without ISPConfig.

if [ -d /usr/local/ispconfig ]; then
    alias ispc='cd /usr/local/ispconfig'
    alias webroot='cd /var/www'
    alias clients='cd /var/www/clients'
    command -v postqueue >/dev/null 2>&1 && alias mailq='postqueue -p'

    ispc_version() {
        local version_file="/usr/local/ispconfig/server/lib/config.inc.php"
        if [ -r "$version_file" ]; then
            grep "ISPC_APP_VERSION" "$version_file" | sed "s/.*'\\([^']*\\)'.*/\\1/"
        else
            echo "ISPConfig version file not readable"
            return 1
        fi
    }

    ispc_services() {
        local units="apache2 nginx mariadb mysql postfix dovecot pure-ftpd-mysql bind9 named rspamd redis-server fail2ban"
        local unit
        for unit in $units; do
            systemctl list-unit-files "$unit.service" >/dev/null 2>&1 || continue
            systemctl is-active --quiet "$unit" && printf "%-18s active\n" "$unit" || printf "%-18s inactive\n" "$unit"
        done

        systemctl list-units 'php*-fpm.service' --all --no-legend 2>/dev/null | awk '{print $1}' | while read -r unit; do
            [ -n "$unit" ] || continue
            systemctl is-active --quiet "$unit" && printf "%-18s active\n" "${unit%.service}" || printf "%-18s inactive\n" "${unit%.service}"
        done
    }

    ispc_logs() {
        local logs="/var/log/ispconfig/cron.log /var/log/mail.log /var/log/syslog /var/log/nginx/error.log /var/log/apache2/error.log"
        local existing=""
        local log
        for log in $logs; do
            [ -r "$log" ] && existing="$existing $log"
        done
        [ -n "$existing" ] || { echo "No known ISPConfig logs are readable"; return 1; }
        tail -F $existing
    }

    siteowner() {
        local target="${1:-.}"
        stat -c '%U:%G' "$target"
    }

    sitecd() {
        [ $# -eq 1 ] || { echo "Usage: sitecd <domain>"; return 2; }
        cd "/var/www/$1"
    }

    __sitecd_complete() {
        local current="${COMP_WORDS[COMP_CWORD]}"
        local sites=""

        if [ -d /var/www ]; then
            sites="$(find /var/www -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -printf '%f\n' 2>/dev/null | grep -Ev '^(apps|clients|conf|html|ispconfig|localhost)$')"
        fi

        mapfile -t COMPREPLY < <(compgen -W "$sites" -- "$current")
    }

    complete -F __sitecd_complete sitecd

    mailq_count() {
        command -v postqueue >/dev/null 2>&1 || { echo "postqueue is not installed"; return 1; }
        postqueue -p | tail -n 1
    }

    web_configtest() {
        command -v apachectl >/dev/null 2>&1 && apachectl configtest
        command -v nginx >/dev/null 2>&1 && nginx -t
    }

    wpcli() {
        local owner
        local target="."

        if [ -f index.php ]; then
            target="index.php"
        fi

        owner="$(stat -c '%U' "$target")" || return 1
        sudo -u "$owner" wp "$@"
    }
fi
