# Always run apt-get update and upgrade before installing any package
exec{'/usr/bin/apt-get update':} -> exec{'/usr/bin/apt-get upgrade -y': timeout => 0} -> Package <| |>

package{[
  'build-essential',
  'bundler',
  'byobu',
  'git',
  'htop',
  'libreadline-dev',
  'ruby',
  'vim-nox',
  'wget',
  'zlib1g-dev',
  'zsh',
]:
  ensure => latest,
}

file{'/home/ubuntu/.config':
  ensure  => directory,
  owner   => 'ubuntu',
  group   => 'ubuntu',
  mode    => '0700',
  recurse => true,
}
