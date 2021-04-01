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

my %record;
my $importer = Catmandu::Importer::MARC::ALEPHSEQ->new(file => $ARGV[0]);
$importer->each(sub {
        
	my $data = $_[0];
	my $sysnum = $data->{'_id'};
	
	$record{$sysnum}{title} = marc_map($data,'245a');
	$record{$sysnum}{institution} = marc_map($data,'852b');
	$record{$sysnum}{level} = marc_map($data,'351c');
	$record{$sysnum}{numb_sort} = marc_map($data,'490i') || marc_map($data,'773j');
	$record{$sysnum}{numb_vorl} = marc_map($data,'490v') || marc_map($data,'773g');
	$record{$sysnum}{linker} = sprintf("%-9.9d", marc_map($data,'490w')) || sprintf("%-9.9d", marc_map($data,'773w')); 
	$record{$sysnum}{linker} = sprintf("%-9.9d", marc_map($data,'773w')) if $record{$sysnum}{linker} == 0 ;
});

foreach (keys %record) {
	unless ($record{$_}{institution} =~ 'Basel UB$') {
		delete $record{$_};
	}
}

my @sysnum;
foreach my $key (sort {$record{$a}{numb_sort} <=> $record{$b}{numb_sort}} keys %record ) {
	push @sysnum, $key;	
	}

my $lookup;
foreach my $key (keys %record) {
    $lookup->{$record{$key}{linker}}->{$key} = $record{$key}{numb_sort};
}




print '// data generated: ', $date->cdate(), "\n"; 
print 'var TREE_ITEMS_P = [', "\n";
print '  [\'Kantonsbibliothek Appenzell Ausserrhoden: Archive von Personen und Organisationen\',\'\',', "\n";

foreach (@sysnum) {
	if ($record{$_}{institution} =~ 'Basel UB$' && $record{$_}{level} =~ 'Hauptabteilung') { 
		print $_, "\n";
		addchildren($_);
		}
	}
print '  ]', "\n" ;
print '];'; 
my $date_end = localtime;
print '// data finished: ', $date_end->cdate(), "\n"; 

exit;
sub addchildren{

	if ( defined $lookup->{$_[0]} ) {
		my $ref = $lookup->{$_[0]};
		foreach my $child (sort {$ref->{$a} <=> $ref->{$b}}  keys %$ref ) {
			print '    ', $child, ' ', $record{$child}{title}, ' ', $record{$child}{numb_vorl}, "\n"; 
			addchildren($child);
#			sort {$lookup{$a} <=> $lookup{$b}}
		}
	}
}
#print Dumper @sysnum;
#print Dumper \@sysnum;
#print Dumper (\%level);

#exit


