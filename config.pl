# undef -> put this parameter in config-local.pl
{
    # database
    db_name => 'mittag',
    db_user => undef,
    db_pass => undef,
    db_host => 'localhost',

    # mail account
    mail_user => undef,
    mail_pass => undef,
    mail_host => undef,
    mail_ssl  => '',

    # paths
    path_web  => '__BASE__/data/',
    path_mail => '__BASE__/mail/',

    # commands
    cmd_lynx      => 'lynx',
    cmd_pdftotext => 'pdftotext',
};
