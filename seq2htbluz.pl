#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';

# Data::Dumper für Debugging
use Data::Dumper;

use IO::File;

die "Argumente: $0 Input-Dokument (alephseq), Output Dokument\n" unless @ARGV == 2;

# Unicode-Support innerhalb des Perl-Skripts
use utf8;
# Unicode-Support für Output
binmode STDOUT, ":utf8";

#Zeit auslesen für Header
use Time::Piece;
my $date = localtime;

# Catmandu-Module
use Catmandu::Importer::MARC::ALEPHSEQ;
use Catmandu::Fix::Inline::marc_map qw(:all);

my $output = IO::File->new(">$ARGV[1]");

my %records;
my $importer = Catmandu::Importer::MARC::ALEPHSEQ->new(file => $ARGV[0]);
$importer->each(sub {
        
	my $data = $_[0];
	my $sysnum = $data->{'_id'};
	
	$records{$sysnum}{title} = marc_map($data,'245a');
	$records{$sysnum}{institution} = marc_map($data,'852b');
	$records{$sysnum}{level} = marc_map($data,'351c');
	$records{$sysnum}{numb_sort} = marc_map($data,'490i');
	$records{$sysnum}{numb_vorl} = marc_map($data,'490v');
	$records{$sysnum}{linker} = sprintf("%-9.9d", marc_map($data,'490w'));
	


});

foreach (keys %records) {
	unless ($records{$_}{institution} =~ 'Luzern ZHB') {
		delete $records{$_};
	}
}

print '// data generated: ', $date->cdate(), "\n"; 
print 'var TREE_ITEMS_P = [', "\n";
print '  [\'Kantonsbibliothek Appenzell Ausserrhoden: Archive von Personen und Organisationen\',\'\',', "\n";

foreach my $key (sort {$records{$a}{numb_sort} <=> $records{$b}{numb_sort}} keys %records ) {
	if ($records{$key}{institution} =~ 'Luzern ZHB' && $records{$key}{level} =~ 'Bestand=Fonds') { 
		print $key, "\n";
		addchildren($key);
		delete $records{$key};
		}
	}
print '  ]', "\n" ;
print '];'; 

exit;
sub addchildren{
 	foreach my $child (sort {$records{$a}{numb_sort} <=> $records{$b}{numb_sort}} keys %records ) {
 		if ($records{$child}{linker} == $_[0]){
				print '    ', $child, "\n";	
				addchildren($child);
				delete $records{$child};
		}
	}
}
#print Dumper @sysnum;
#print Dumper \@sysnum;
#print Dumper (\%level);

#exit


