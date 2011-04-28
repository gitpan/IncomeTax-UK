package IncomeTax::UK;

use strict; use warnings;

use overload q("") => \&as_string, fallback => 1;

use Carp;
use Readonly;
use Data::Dumper;

=head1 NAME

IncomeTax::UK - Interface to Income Tax of UK.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

Readonly my $UPPER_LIMIT => 150_000;

Readonly my $PERSONAL_ALLOWANCE =>
{
    '2010-11' => 6475,
    '2011-12' => 7475,
};

Readonly my $TAX_BAND =>
{
    2440  => { dividend => 0,     savings => 0.10, other => 0    },
    37400 => { dividend => 0.10,  savings => 0.20, other => 0.20 },
    37401 => { dividend => 0.325, savings => 0.40, other => 0.40 },
};

Readonly my $ADDITIONAL =>
{
    dividend => 0.425, savings => 0.50, other => 0.50
};

=head1 DESCRIPTION

Income tax forms  the  bulk of revenues collected by the government. Each person has an income
tax personal allowance and  income upto this amount in each tax year is tax free for everyone.
For  2010-11  the  tax  allowance  for under 65s is GBP 6,475. On 22 June 2010, the Chancellor 
(George Osborne) increased the personal allowance by GBP 1000 in his emergency budget bringing
it to GBP 7,475 for the tax year 2011-12.

    +------+----------+-------------------+
    | Age  | Tax Year | Persoal Allowance |
    +------+----------+-------------------+
    | < 65 | 2010-11  | GBP 6,475         |
    | < 65 | 2011-12  | GBP 7,475         |
    +------+----------+-------------------+

    +------------+----------+---------+------------------+---------------------------+
    | Rate       | Dividend | Savings | Other            | Band                      |
    |            |          |         | (inc employment) | (Above personal allowance)|
    +------------+----------+---------+------------------+---------------------------+
    | Lower      | N/A      | 10%     | N/A              | GBP 0 - GBP 2440          |
    | Basic      | 10%      | 20%     | 20%              | GBP 0 - GBP 37,400        |
    | Higher     | 32.5%    | 40%     | 40%              | over GBP 7,400            |
    | Additional | 42.5%    | 50%     | 50%              | over GBP 150,000          |
    +------------+----------+---------+------------------+---------------------------+

=cut

sub new
{
    my $class = shift;
    my $param = shift;
    
    _validate_param($param);
    bless $param, $class;
    return $param;
}

=head1 METHODS

=head2 get_tax_amount()

Returns the tax amount for given type in the given tax year. Possible values for types are as:

    +------------------------+----------+
    | Type                   | Value    |
    +------------------------+----------+
    | Dividend               | dividend |
    | Savings                | savings  |
    | Other (inc employment) | other    |
    +------------------------+----------+
    
Default is other i.e. Income Tax.    

=cut

sub get_tax_amount
{
    my $self   = shift;
    my $amount = shift;
    my $type   = shift;
    $type = 'other' unless defined $type;
    
    croak("ERROR: Missing gross amount.\n")
        unless defined $amount;
    croak("ERROR: Invalid value for gross amount [$amount].\n")
        unless ($amount =~ /^\d+\.?\d+?$/);
    croak("ERROR: Invalid value for tax type [$type].\n")
        unless (defined($type) && ($type =~ /^\bdividend\b|\bsavings\b|\bother\b$/i));

    my ($allowance, $taxable);
    $allowance = 0;
    $allowance = $PERSONAL_ALLOWANCE->{$self->{tax_year}}
        if ($self->{age} < 65);
        
    $self->{gross}     = $amount;
    $self->{allowance} = $allowance;    
    
    $taxable = $amount - $allowance;
    $amount  = $taxable * _get_band($type, $amount);
    
    $self->{taxable}      = $taxable;
    $self->{standard_tax} = $amount;
    
    $amount += ($taxable-$UPPER_LIMIT) * $ADDITIONAL->{$type}
        if ($taxable > $UPPER_LIMIT);
        
    $self->{additional_tax} = $amount - $self->{standard_tax}
        if ($amount - $self->{standard_tax} > 0);
    $self->{nett_tax} = $amount;    

    return sprintf("%.02f", $amount);
}

=head2 get_breakdown()

Returns the calculation breakdown. You  should ONLY  be calling after method get_tax_amount().
Otherwise if it would simply return nothing.

    use stric; use warnings;
    use IncomeTax::UK;
    
    my $uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
    my $income_tax = $uk->get_tax_amount(55000);
    print $uk->get_breakdown();

=cut

sub get_breakdown
{
    my $self = shift;
    return $self->as_string();
}

=head2 as_string()

Same as get_breakdown() except that it gets called when printing object in scalar context.

    use stric; use warnings;
    use IncomeTax::UK;
    
    my $uk = IncomeTax::UK->new({age => 35, tax_year => '2010-11'});
    my $income_tax = $uk->get_tax_amount(55000);
    print $uk->as_string();
    
    # or simply
    
    print $uk;

=cut

sub as_string
{
    my $self   = shift;
    my $string = sprintf("         Gross: %.02f\n", $self->{gross});
    $string   .= sprintf("       Taxable: %.02f\n", $self->{taxable});
    $string   .= sprintf("  Standard Tax: %.02f\n", $self->{standard_tax});
    $string   .= sprintf("Additional Tax: %.02f\n", $self->{additional_tax})
        if exists($self->{additional_tax});
    $string   .= "-------------------------\n";
    $string   .= sprintf("       Net Tax: %.02f\n", $self->{nett_tax});
    $string   .= "-------------------------\n";
    return $string;
}

sub _get_band
{
    my $type   = shift;
    my $amount = shift;
    
    foreach (keys %{$TAX_BAND})
    {
        return $TAX_BAND->{$_}->{$type} if ($_ <= $amount);
    }
    return 0;
}

sub _validate_param
{
    my $param = shift;
    croak("ERROR: Missing input parameters.\n") 
        unless defined $param;
    croak("ERROR: Input param has to be a ref to HASH.\n")
        if (ref($param) ne 'HASH');
    croak("ERROR: Missing key age.\n")
        unless exists($param->{age});
    croak("ERROR: Missing key tax_year.\n")
        unless exists($param->{tax_year});
    croak("ERROR: Invalid value for key age.\n")
        unless ($param->{age} =~ /^\d+$/);
    croak("ERROR: Invalid value for key tax_year.\n")
        unless (($param->{tax_year} =~ /^\d{4}\-\d{2}$/) 
                && 
                ($param->{tax_year} =~ /^2010-11|2011-12$/));
    croak("ERROR: Invalid number of keys found in the input hash.\n")
        unless (scalar(keys %{$param}) == 2);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs  or feature requests to C<bug-incometax-uk at rt.cpan.org>,  or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IncomeTax-UK>. I will be 
notified and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IncomeTax::UK

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IncomeTax-UK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IncomeTax-UK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IncomeTax-UK>

=item * Search CPAN

L<http://search.cpan.org/dist/IncomeTax-UK/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This  program  is  free  software; you can redistribute it and/or modify it under the terms of
either:  the  GNU  General Public License as published by the Free Software Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This  program  is  distributed  in  the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

1; # End of IncomeTax::UK