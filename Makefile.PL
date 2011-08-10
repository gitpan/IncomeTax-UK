use strict;use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'IncomeTax::UK',
    AUTHOR        => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM  => 'lib/IncomeTax/UK.pm',
    ABSTRACT_FROM => 'lib/IncomeTax/UK.pm',
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'IncomeTax-UK-*' },
    PREREQ_PM     => {
        'Test::More' => 0,
        'Readonly'   => '1.03',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
);