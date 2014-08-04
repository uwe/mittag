# undef -> put this parameter in config-local.pl
{
    # database
    db_name => 'mittag',
    db_user => undef,
    db_pass => undef,
    db_host => 'localhost',

    # paths
    path_web  => '__BASE__/data/',

    # commands
    cmd_lynx      => 'lynx',
    cmd_pdftotext => 'pdftotext',
};
