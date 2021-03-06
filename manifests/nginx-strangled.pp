###########################################################
###
### Notice the bunch of templates below
### Skip to the 'CONFIGURATION' section for the real meat
###
###########################################################

$port = 4000

$legacy_nginx_conf_template = @(END)
# This file is managed by Puppet
# DO NOT EDIT!

upstream legacy {
  server 127.0.0.1:<%= @port %>;
}

upstream replacement {
  server 127.0.0.1:<%= @port + 1 %>;
}

server {
  listen 80 default;
  server_name <%= @ipaddress %>;

  location /report {
    proxy_pass http://replacement;
  }

  location / {
    proxy_pass http://legacy;
  }
}

END

$nginx_conf_template = @(END)
user www-data;
worker_processes auto;
pid /run/nginx.pid;
events {
  worker_connections 768;
}
http {
  sendfile off;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;
  gzip on;
  gzip_disable "msie6";
  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}
END

$nginx_mime_types_template = @(END)
types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    application/javascript                js;
    application/atom+xml                  atom;
    application/rss+xml                   rss;

    text/mathml                           mml;
    text/plain                            txt;
    text/vnd.sun.j2me.app-descriptor      jad;
    text/vnd.wap.wml                      wml;
    text/x-component                      htc;

    image/png                             png;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/x-icon                          ico;
    image/x-jng                           jng;
    image/x-ms-bmp                        bmp;
    image/svg+xml                         svg svgz;
    image/webp                            webp;

    application/font-woff                 woff;
    application/java-archive              jar war ear;
    application/json                      json;
    application/mac-binhex40              hqx;
    application/msword                    doc;
    application/pdf                       pdf;
    application/postscript                ps eps ai;
    application/rtf                       rtf;
    application/vnd.apple.mpegurl         m3u8;
    application/vnd.ms-excel              xls;
    application/vnd.ms-fontobject         eot;
    application/vnd.ms-powerpoint         ppt;
    application/vnd.wap.wmlc              wmlc;
    application/vnd.google-earth.kml+xml  kml;
    application/vnd.google-earth.kmz      kmz;
    application/x-7z-compressed           7z;
    application/x-cocoa                   cco;
    application/x-java-archive-diff       jardiff;
    application/x-java-jnlp-file          jnlp;
    application/x-makeself                run;
    application/x-perl                    pl pm;
    application/x-pilot                   prc pdb;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager  rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash         swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert            der pem crt;
    application/x-xpinstall               xpi;
    application/xhtml+xml                 xhtml;
    application/xspf+xml                  xspf;
    application/zip                       zip;

    application/octet-stream              bin exe dll;
    application/octet-stream              deb;
    application/octet-stream              dmg;
    application/octet-stream              iso img;
    application/octet-stream              msi msp msm;

    application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
    application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;

    audio/midi                            mid midi kar;
    audio/mpeg                            mp3;
    audio/ogg                             ogg;
    audio/x-m4a                           m4a;
    audio/x-realaudio                     ra;

    video/3gpp                            3gpp 3gp;
    video/mp2t                            ts;
    video/mp4                             mp4;
    video/mpeg                            mpeg mpg;
    video/quicktime                       mov;
    video/webm                            webm;
    video/x-flv                           flv;
    video/x-m4v                           m4v;
    video/x-mng                           mng;
    video/x-ms-asf                        asx asf;
    video/x-ms-wmv                        wmv;
    video/x-msvideo                       avi;
}
END


#############################################
###
### CONFIGURATION
###
#############################################

package{'nginx':
  ensure => present,
} -> service{'nginx':
  ensure  => running,
}

file{[
  '/etc/nginx',
  '/etc/nginx/sites-enabled',
]:
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file{'/etc/nginx/mime.types':
  ensure  => file,
  mode    => '0644',
  notify  => Service['nginx'],
  content => inline_template($nginx_mime_types_template),
}

file{'/etc/nginx/nginx.conf':
  ensure  => file,
  mode    => '0644',
  notify  => Service['nginx'],
  content => inline_template($nginx_conf_template),
}

file{'/etc/nginx/sites-enabled/default':
  ensure  => file,
  mode    => '0644',
  notify  => Service['nginx'],
  content => inline_template($legacy_nginx_conf_template),
}

# service{'legacy':
#   ensure   => running,
#   start    => "cd /vagrant/nginx-reverse-proxy/legacy && /usr/bin/bundle exec ruby app.rb -o 127.0.0.1 -e production -p ${port}",
#   provider => 'systemd',
# }
#
# service{'replacement':
#   ensure   => running,
#   start    => inline_template("cd /vagrant/nginx-reverse-proxy/replacement && /usr/bin/bundle exec ruby app.rb -o 127.0.0.1 -e production -p <%= @port + 1 %>"),
#   provider => 'systemd',
# }
