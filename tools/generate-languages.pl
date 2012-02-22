use FindBin qw($Bin);
use lib "$Bin/../lib/";

use Code::Generator::Perl;
use LWP::Simple ();
use XML::Simple ();
use DateTime;
use File::HomeDir;
use Net::TVDB;

# Get the current list of languages
my $api_key_file = File::HomeDir->my_home . '/.tvdb';
die 'Can not get API key' unless -e $api_key_file;
my $api_key = Net::TVDB::_get_api_key_from_file($api_key_file);
my $xml = LWP::Simple::get("http://www.thetvdb.com/api/$api_key/languages.xml");
die 'Could not get XML' unless $xml;
my $languages = XML::Simple::XMLin($xml);

# Generate the package
my $generator = new Code::Generator::Perl(
    outdir       => "$Bin/../lib/",
    generated_by => 'tools/generate-languages.pl'
);
$generator->new_package('Net::TVDB::Languages');

$generator->add_comment(
    'ABSTRACT: A list of languages supported by thetvdb.com');

# Add the code
my $export = <<'HERE';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw($languages);
HERE
$generator->_add_content($export);

$generator->add( languages => $languages->{Language} );

# Generate the POD
my $now = DateTime->now->ymd;
my $pod = <<"HERE";
=head1 SYNOPSIS

  use Net::TVDB::Languages qw(\$langauges);

=head1 DESCRIPTION

This contains all the langauges supported by http://thetvdb.com as of $now.

They are as follows:

=over 4

HERE

for ( keys %{ $languages->{Language} } ) {
    $pod .= <<"HERE";
=item *

$_

HERE
}

$pod .= <<'HERE';
=back

=cut
HERE
$generator->_add_content($pod);

# Write to file
$generator->create_or_die();