#!/usr/bin/env sh
# Bash script that copies plexreport files to various directories
# and walks the user through the initial setup
#

PLEX_REPORT_LIB='/var/lib/plexReport'
PLEX_REPORT_CONF='/etc/plexReport'

/bin/echo "Creating plexreport library at /var/lib/plexReport"
/bin/mkdir -p $PLEX_REPORT_LIB
/bin/echo "Creating plexreport conf directory at /etc/plexReport"
/bin/mkdir -p $PLEX_REPORT_CONF

/bin/echo "Moving plexreport and plexreport-setup to /usr/local/sbin"
/bin/cp -r bin/* /usr/local/sbin
/bin/echo "Moving plexreport libraries to /var/lib/plexreport"
/bin/cp -r lib/* $PLEX_REPORT_LIB
/bin/echo "Moving email_body.erb to /etc/plexreport"
/bin/cp -r etc/* $PLEX_REPORT_CONF

/bin/echo "Creating /etc/plexreport/config.yaml"
/usr/bin/touch /etc/plexReport/config.yaml
/bin/echo "Creating /var/log/plexReport.log"
/usr/bin/touch /var/log/plexReport.log

GEM_BINARY=$(whereis gem | cut -d':' -f2 | cut -d' ' -f2)
if [ "$GEM_BINARY" = "" ]; then
    /bin/echo "Installing ruby"
    if [ $(uname) = "FreeBSD" ]; then
        pkg install -y ruby devel/ruby-gems
    else # RedHat/CentOS/Ubuntu/Debian
        source /etc/os-release
        case $NAME in
            "Red Hat Enterprise Linux Server"|"CentOS Linux") yum install -y ruby ruby-devel make gcc ;;
            "Debian GNU/Linux"|"Ubuntu") apt-get update && apt-get install -y ruby ruby-dev make gcc;;
        esac
    fi
    GEM_BINARY=$(whereis gem | cut -d':' -f2 | cut -d' ' -f2)
    if [ "$GEM_BINARY" = "" ]; then
       echo "Something went wrong while installing ruby!"
       exit 1
    fi
fi

/bin/echo "Installing ruby gem dependency"
$GEM_BINARY install bundler
BUNDLER=$(whereis bundle | cut -d':' -f2 | cut -d' ' -f2)
$BUNDLER install

/bin/echo "Running /usr/local/sbin/plexreport-setup"
/usr/local/sbin/plexreport-setup

/bin/echo "What day do you want to run the script on? (Put 0 for Sunday, 1 for Monday, etc...)"
read CRON_DAY
/bin/echo "What hour should the script run? (00-23)"
read CRON_HOUR
/bin/echo "What minute in that hour should the script run? (00-59)"
read CRON_MINUTE

/bin/echo "Adding /usr/local/sbin/plexreport to crontab"
/usr/bin/crontab -l > mycron

# Add PATH only if it crontab doesn't have it
if grep -q '^PATH' mycron; then
    sed 's|^PATH.*|PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin|' -i mycron
else
    sed '1 i PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin' -i mycron 
fi
if ! grep -q '/usr/local/sbin/plexreport$' mycron; then
    /bin/echo "$CRON_MINUTE $CRON_HOUR * * $CRON_DAY /usr/local/sbin/plexreport" >> mycron
fi
/usr/bin/crontab mycron
/bin/rm mycron

/bin/echo "Setup complete!"
