use strict;use warnings;
use Module::Build;

my $builder = Module::Build->new(
    sign              => 1,
    module_name       => 'IncomeTax::UK',
    license           => 'perl',
    dist_author       => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    dist_version_from => 'lib/IncomeTax/UK.pm',
    add_to_cleanup    => [ 'IncomeTax-UK-*' ],    
    build_requires    => {
        'Test::More'  => 0,
        'Readonly'    => 0,
    },
);

$builder->create_build_script();