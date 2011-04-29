#!perl

use strict; use warnings;
use IncomeTax::UK;
use Test::More tests => 16;

my ($uk);

eval { $uk = IncomeTax::UK->new(); };
like($@, qr/ERROR: Missing input parameters./);

eval { $uk = IncomeTax::UK->new(age => 35); };
like($@, qr/ERROR: Input param has to be a ref to HASH./);

eval { $uk = IncomeTax::UK->new({aeg => 35}); };
like($@, qr/ERROR: Missing key age./);

eval { $uk = IncomeTax::UK->new({age => 35, taxyear => '2010-11'}); };
like($@, qr/ERROR: Missing key tax_year./);

eval
{
    $uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
    $uk->get_tax_amount();
};
like($@, qr/ERROR: Missing gross amount./);

eval { $uk = IncomeTax::UK->new({age => 'ab', tax_year => '2010-11'}); };
like($@, qr/ERROR: Invalid value for key age./);

eval { $uk = IncomeTax::UK->new({age => 35, tax_year => '2010,11'}); };
like($@, qr/ERROR: Invalid value for key tax_year./);

eval { $uk = IncomeTax::UK->new({age => 35, tax_year => '2012-13'}); };
like($@, qr/ERROR: Invalid value for key tax_year./);

eval
{
    $uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
    $uk->get_tax_amount('abc');
};
like($@, qr/ERROR: Invalid value for gross amount./);

eval
{
    $uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
    $uk->get_tax_amount(55000, 'abc');
};
like($@, qr/ERROR: Invalid value for tax type \[abc\]./);

eval { $uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11', abc => 1}); };
like($@, qr/ERROR: Invalid number of keys found in the input hash./);

$uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
is($uk->get_tax_amount(159000), "62272.5");

$uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
is($uk->get_tax_amount(55000), "19410");

$uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
is($uk->get_tax_amount(55000, 'other'), "19410");

$uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
is($uk->get_tax_amount(55000, 'dividend'), "15770.625");

$uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
is($uk->get_tax_amount(55000, 'savings'), "19410");