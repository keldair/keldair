package SpamCalc;

# ---------------------------------------------------------------------
# $Id: SpamCalc.pm,v 1.3 2003/08/09 12:45:33 spamcalc Exp $
# ---------------------------------------------------------------------
# SpamCalc calculation module.
# ---------------------------------------------------------------------
# By Joost "Garion" Vunderink
# This file is part of spamcalc.
# See http://spamcalc.net/ for more information.
# ---------------------------------------------------------------------

use strict;
use Cwd;
use vars qw($VERSION);

($VERSION) = '$Revision: 1.3 $' =~ / (\d+\.\d+)/;


# ---------------------------------------------------------------------
# Constructor.

sub new {
	my ($proto) = @_;
	my $class = ref($proto) || $proto;

	my $self = {
		owndir			=> undef,
		datadirs		=> undef,
		moduledirs		=> undef,

		datadir         => "data",
		debuglevel      => 0,

		wordvalue       => undef,
		regexpvalue     => undef,
		domainvalue     => undef,
		rfields         => undef,
		tlds            => undef,
		
		whitetree		=> undef,
		blacktree		=> undef,
		numwhitetree	=> 0,
		numblacktree	=> 0,

		dummy			=> 0,
	};

	bless ($self, $class);
	$self->init_dirs();
	return $self;
}

# ---------------------------------------------------------------------
# Inits the dirs from which the data files can be read.

sub init_dirs {
	my ($self) = @_;

	my $owndir;
    if (substr($0, 0, 1) eq "/") {
        $owndir = $0;
    } else {
        $owndir = getcwd() . "/" . $0;
    }
    $owndir =~ s/\/[^\/]+$//g;
	$self->{owndir} = $owndir;

	$self->{datadirs} = ["./data", $owndir."/data", "/etc/spamcalc", "/usr/local/spamcalc/etc"];
}


# =====================================================================
# Public functions.
# =====================================================================

# =====================================================================
# Loading spamcalc data from files.

# ---------------------------------------------------------------------
# Loads all the words and regexps and more data.
# If $datadir is defined, and that directory exists, the files are 
# loaded from that directory. If it does not exist, 0 is returned, and
# no datafiles are loaded.
# If no $datadir is given, the datafiles are loaded from any of the
# locations specified in sub init_dirs.

sub load_datafiles {
	my ($self, $datadir) = @_;

	$self->{datadir} = "";

	if (defined($datadir) && length($datadir) > 0) {
		if ($datadir =~ /^\//) {
			$self->{datadir} = $datadir;
		} else {
			$self->{datadir} = getcwd() . "/$datadir";
		}
		
		if (!-d $self->{datadir}) {
			return 0;
		}
	} else {
		foreach my $dir (@{ $self->{datadirs} } ) {
			if (-d $dir) {
				$self->{datadir} = $dir;
				last;
			}
		}
		if (!$self->{datadir}) {
			return 0;
		}
	}
	
	undef($self->{wordvalue});
	undef($self->{regexpvalue});
	undef($self->{rfields});
	undef($self->{tlds});
	undef($self->{whitetree});
	undef($self->{blacktree});

	$self->ReadDataFiles("words",     \%{ $self->{wordvalue} },   "hash");
	$self->ReadDataFiles("regexp",    \%{ $self->{regexpvalue} }, "hash");
	$self->ReadDataFiles("fields",    \@{ $self->{rfields} },     "array");
	$self->ReadDataFiles("tld",       \@{ $self->{tlds} },        "array");

	$self->{numwhitetree} = 
		$self->ReadDataFiles("whitelist", \%{ $self->{whitetree} },   "tree");
	$self->{numblacktree} = 
		$self->ReadDataFiles("blacklist", \%{ $self->{blacktree} },   "tree");

	return $self->{datadir};
}


# =====================================================================
# Obtaining properties of hosts, words and domains.

# ---------------------------------------------------------------------
# Returns the information hash of a hostname.

sub get_host_info {
	my ($self, $hostname) = @_;

	my $hostinfo = $self->GetHostInfo($hostname, 0);

	return $hostinfo;
}

# ---------------------------------------------------------------------
# Returns the dnsspam score of a hostname.

sub get_host_score {
	my ($self, $hostname) = @_;

	my $hostinfo = $self->GetHostInfo($hostname, 1);

	return $hostinfo->{score};
}

# ---------------------------------------------------------------------
# Returns the field score of just one word.

sub get_field_score {
	my ($self, $word) = @_;

	my $score = $self->CalcWordScore(lc($word));

	if ($score > 0) {
		return $score;
	} else {
		return $self->CalcRegexpScore($word);
	}
}

# ---------------------------------------------------------------------
# Returns the word score of just one word.

sub get_word_score {
	my ($self, $word) = @_;

	return $self->CalcWordScore(lc($word));
}

# ---------------------------------------------------------------------
# Returns the regexp score of just one word.

sub get_regexp_score {
	my ($self, $word) = @_;

	return $self->CalcRegexpScore($word);
}

# ---------------------------------------------------------------------
# Checks if this host is on the blacklist.
# Returns 0 if it is not, and N > 0 if it is.

sub get_blacklist_score {
	my($self, $hostname) = @_;

	return $self->GetBlacklistScore($hostname);
}

# ---------------------------------------------------------------------
# Checks if this host is on the blacklist.
# Returns 0 if it is not, and N > 0 if it is.

sub get_whitelist_score {
	my($self, $hostname) = @_;

	return $self->GetWhitelistScore($hostname);
}

# ---------------------------------------------------------------------
# Returns the number of words currently in the hash.

sub get_num_words {
	my ($self) = @_;

	return scalar keys %{ $self->{"wordvalue"} };
}

# ---------------------------------------------------------------------
# Returns the number of regexps currently in the hash.

sub get_num_regexps {
	my ($self) = @_;

	return scalar keys %{ $self->{"regexpvalue"} };
}

# ---------------------------------------------------------------------
# Returns the number of domains currently on the blacklist.

sub get_num_blacklist {
	my ($self) = @_;

	return $self->{numblacktree};
}

# ---------------------------------------------------------------------
# Returns the number of domains currently on the whitelist.

sub get_num_whitelist {
	my ($self) = @_;

	return $self->{numwhitetree};
}

# =====================================================================
# Adding data to the score hashes, arrays and trees.

# ---------------------------------------------------------------------
# Adds a new word to the word list. This only affects the words
# currently in memory. Does NOT save this word into a file.

sub add_word {
	my ($self, $word, $penalty) = @_;

	if ($penalty > 0) {
		$self->{wordvalue}{$word} = $penalty;
	} else {
		undef($self->{wordvalue}{$word});
	}
	return 1;
}

# ---------------------------------------------------------------------
# Adds a new regexp to the regexp list. This only affects the regexps
# currently in memory. Does NOT save this regexp into a file.

sub add_regexp {
	my ($self, $regexp, $penalty) = @_;

	if ($penalty > 0) {
		$self->{regexpvalue}{$regexp} = $penalty;
	} else {
		undef($self->{regexpvalue}{$regexp});
	}
	return 1;
}

# ---------------------------------------------------------------------
# Adds a new domain to the blacklist. This only affects the data 
# currently in memory. Does NOT save this data into a file.

sub add_blacklist {
	my ($self, $domain, $score) = @_;

	AddItemToTree($self->{blacktree}, "\\\.", $domain, $score);
	$self->{numblacktree} = $self->{numblacktree} + 1;

	return 1;
}

# ---------------------------------------------------------------------
# Adds a new domain to the blacklist. This only affects the data 
# currently in memory. Does NOT save this data into a file.

sub add_whitelist {
	my ($self, $domain, $score) = @_;

	AddItemToTree($self->{whitetree}, "\\\.", $domain, $score);
	$self->{numwhitetree} = $self->{numwhitetree} + 1;

	return 1;
}

# =====================================================================
# Miscellaneous functions.

# ---------------------------------------------------------------------
# Without arguments, this returns the current debug level; with
# argument, it sets the debug level.

sub debuglevel {
	my $self = shift;
	if (@_) { $self->{debuglevel} = shift; }
	return $self->{debuglevel};
}


# =====================================================================
# Private functions
# =====================================================================


# =====================================================================
# Reading datafiles

# ---------------------------------------------------------------------
# Looks in the data dir for datafiles and reads them.
# All filenames are checked and if they are of the correct form, they
# are assumed to be a valid datafile for that type and then loaded.
# Returns the total number of items added to the dataref.

sub ReadDataFiles {
	my ($self, $type, $dataref, $datatype) = @_;

	if (! -d $self->{datadir}) {
		print("Can't locate data dir " . $self->{datadir} . "\n");
		return;
	}

	opendir(DATADIR, $self->{datadir});

	my $numitems = 0;
	while (my $filename = readdir(DATADIR)) {
		if ($filename =~ /^$type/) {
			$numitems += ReadDataFile($self, $self->{datadir} . "/" . $filename, $dataref, $datatype);
		}
	}

	closedir(DATADIR);

	return $numitems;
}

# ---------------------------------------------------------------------
# Reads all the data in a data file and adds it to the given hash/array.

sub ReadDataFile {
	my ($self, $datafile, $dataref, $datatype) = @_;

	if (!($datatype eq "hash" || $datatype eq "array" || $datatype eq "tree")) {
		print STDERR ("ReadDataFile: Unknown data file type $datatype.\n");
		return;
	}

	if (! -e $datafile) {
		print STDERR ("ReadDataFile: Data file $datafile does not exist.\n");
		return;
	}

	open(DATAFILE, $datafile);
	my @datalines = <DATAFILE>;
	chomp @datalines;
	close(DATAFILE);

	if (scalar @datalines == 0) {
		print STDERR ("ReadDataFile: Data file $datafile is empty.\n");
		return;
	}

	if ($datatype eq "hash") {
		return $self->ReadHashFromLines($dataref, @datalines);
	}

	if ($datatype eq "array") {
		return $self->ReadArrayFromLines($dataref, @datalines);
	}

	if ($datatype eq "tree") {
		return $self->ReadTreeFromLines($dataref, "\\\.", @datalines);
	}
}

# ---------------------------------------------------------------------

sub ReadHashFromLines {
	my ($self, $dataref, @datalines) = @_;

	foreach my $dataline (@datalines) {
		$dataline =~ tr/A-Z/a-z/;
		$dataline =~ s/#.*//;
		$dataline =~ s/^\s+|\s+$//;
		if ($dataline =~ /\s*([^\s]+)\s+(\d+)/ ) {
			# If this piece of data already exists in the hash, only replace
			# it if this score value is higher than the existing one.
			if (defined($dataref->{$1})) {
				if ($dataref->{$1} < $2) {
					$self->dprint("Updated score of $1 from $dataref->{$1} to $2.\n", 4);
					$dataref->{$1} = $2;
				} else {
					$self->dprint("$1 with score $dataref->{$1} already present.\n", 4);
				}
			} else {
				$dataref->{$1} = $2;
				$self->dprint("Added $1 with score $2.\n", 4);
			}
		}
	}
}

# ---------------------------------------------------------------------

sub ReadArrayFromLines {
	my ($self, $dataref, @datalines) = @_;

	foreach my $dataline (@datalines) {
		$dataline =~ tr/A-Z/a-z/;
		$dataline =~ s/#.*//;
		$dataline =~ s/ //g;
		if ($dataline =~ /[a-z0-9]/) {
			push(@{$dataref}, $dataline);
		}
	}
}

# ---------------------------------------------------------------------
# Adds data from these lines to the tree $dataref.
# Returns the number of lines added.

sub ReadTreeFromLines {
	my ($self, $dataref, $separator, @datalines) = @_;

	my $numitems = 0;
	
	foreach my $dataline (@datalines) {
		$dataline =~ tr/A-Z/a-z/;
		$dataline =~ s/#.*//;
		$dataline =~ s/^\s+//g;
		$dataline =~ s/\s+$//g;
		
		my $key;
		my $value = 1;
		if ($dataline =~ /^([^\s]+)\s+([0-9]+)$/) {
			$key = $1;
			$value = $2;
		}
		if ($dataline =~ /^([^\s]+)$/) {
			$key = $1;
		}

		if ($key) {
			$self->AddItemToTree($dataref, $separator, lc($key), $value);
			# TODO: check whether this item has already been added so
			# $numitems doesn't increase by 2 if adding the same
			# item twice.
			$numitems++;
		}
	}

	return $numitems;
}

# ---------------------------------------------------------------------

sub AddItemToTree {
	my ($self, $dataref, $separator, $key, $value) = @_;

	my @branches = split(/$separator/, $key);
	my $currentref = $dataref;

	while (my $tempref = pop(@branches)) {
		$currentref = \%{ $currentref->{$tempref} };
	}
	$currentref->{"#"} = $value;
}


# =====================================================================
# Calculation function

# ---------------------------------------------------------------------
# The core function. Creates a hostinfo hash, fills it up with the
# relevant data about the hostname, and returns it.
# First argument is the hostname to determine the info of.
# Second argument is whether to get the full info (1) or only the
# dnsspam score (0). Using 0 as second argument means a big speedup.

sub GetHostInfo {
	my ($self, $hostname, $getfullinfo) = @_;

	my %hostinfo;
	$hostinfo{"hostname"} = $hostname;
	$hostinfo{"getfullinfo"} = $getfullinfo;

	($hostinfo{"hostpart"}, $hostinfo{"domainpart"}) = 
		$self->SplitHostname($hostname);

	foreach my $field (split(/\./, $hostinfo{"hostpart"})) {
		push @{ $hostinfo{"hostfields"} }, $field;
	};

	$self->InitHostInfo(\%hostinfo);
	$self->CalcWhitelistScore(\%hostinfo);
	$self->CalcBlacklistScore(\%hostinfo);
	$self->CalcFieldScores(\%hostinfo);
	$self->CalcNumFieldScore(\%hostinfo);
	$self->CalcFieldLengthScore(\%hostinfo);
	$self->CalcDashesScore(\%hostinfo);
	$self->CalcLooksLikeWordScore(\%hostinfo);
	$self->CalcRepeatScore(\%hostinfo);
	$self->CalcOneLetterScore(\%hostinfo);

	$self->CalcTotalScore(\%hostinfo);
	return \%hostinfo;
}

# ---------------------------------------------------------------------
# Sets all scores and multipliers to the base values to prevent getting
# errors about uninitialized values.
# First argument is a reference to a host info hash.

sub InitHostInfo {
	my($self, $hiref) = @_;

	$hiref->{"isblacklisted"} = 0;
	$hiref->{"blacklistscore"} = 0;
	$hiref->{"iswhitelisted"} = 0;
	$hiref->{"whitelistscore"} = 0;

	$hiref->{"twordscore"} = 0;
	$hiref->{"tregexpscore"} = 0;

	$hiref->{"repeatscore"} = 0;
	$hiref->{"oneletterscore"} = 0;
	$hiref->{"dashesscore"} = 0;
	$hiref->{"numfieldscore"} = 0;
	$hiref->{"fieldlengthscore"} = 0;
	$hiref->{"lookslikewordscore"} = 0;
}

# ---------------------------------------------------------------------
# Checks if this host is on the blacklist.
# First argument is a reference to a host info hash.

sub CalcBlacklistScore {
	my($self, $hiref) = @_;

	my @fields = split(/\./, $hiref->{"hostname"});
	my $ref = $self->{"blacktree"};
	my $blacklistdomain = "";

	# The fields have been lowercased before entering the tree so
	# lowercase each field here.
	while (my $field = lc(pop(@fields))) {
		if (defined($ref->{$field})) {
			$blacklistdomain = "." . $field . $blacklistdomain;
			$ref = \%{ $ref->{$field} };
			if (defined($ref->{"#"}) && $ref->{"#"} > $hiref->{"blacklistscore"}) {
				$hiref->{"isblacklisted"} = 1;
				$hiref->{"blacklistscore"} = $ref->{"#"};
				$hiref->{"blacklistdomain"} = $blacklistdomain;
				#return $ref->{"#"};
			}
		} else {
			return 0;
		}
	}

	return $hiref->{"blacklistscore"};
}

# ---------------------------------------------------------------------
# Checks if this host is on the blacklist.
# First argument is a reference to a host info hash.

sub CalcWhitelistScore {
	my($self, $hiref) = @_;

	my @fields = split(/\./, $hiref->{"hostname"});
	my $ref = $self->{"whitetree"};
	my $whitelistdomain = "";

	# The fields have been lowercased before entering the tree so
	# lowercase each field here.
	while (my $field = lc(pop(@fields))) {
		if (defined($ref->{$field})) {
			$whitelistdomain = "." . $field . $whitelistdomain;
			$ref = \%{ $ref->{$field} };
			if (defined($ref->{"#"})) {
				$hiref->{"iswhitelisted"} = 1;
				$hiref->{"whitelistscore"} = 100;
				$hiref->{"whitelistdomain"} = $whitelistdomain;
				return 100;
			}
		} else {
			return 0;
		}
	}

	return 0;
}


# ---------------------------------------------------------------------
# Calculates both the regexp and the word penalties for all the fields
# in the host part.
# First argument is a reference to a host info hash.

sub CalcFieldScores {
	my ($self, $hiref) = @_;

	foreach my $hostfield (@{ $hiref->{"hostfields"} }) {
		my $wordscore = $self->CalcWordScore($hostfield, $hiref);
		my $regexpscore = $self->CalcRegexpScore($hostfield, $hiref);

		$hiref->{"twordscore"} += $wordscore;
		$hiref->{"tregexpscore"} += $regexpscore;
	}
}

# ---------------------------------------------------------------------
# Calculates the penalty for fields that contain a dash (-) sign.
# First argument is a reference to a host info hash.

sub CalcDashesScore{
	my ($self, $hiref) = @_;

	foreach my $hostfield (@{ $hiref->{"hostfields"} }) {
		if ($hostfield !~ /-/) {
			next;
		}

		# Test if the field consists only of single letters between
		# the dashes.
	  	if ($hostfield =~ /^([a-zA-Z0-9]-)+[a-zA-Z0-9]$/) {
			$hiref->{"dashesscore"} += 50;
			next;
		}

		# Calculate the penalty score for each subfield, separated
		# by the dashes.
		my ($score, $multiplier) = (0, 0);
		my @subfields = split(/-/, $hostfield);

		# Same way as the words score: multiply the total score
		# by the number of fields that caused this score.
		foreach my $subfield (@subfields) {
			my $wordscore = $self->CalcWordScore($subfield);
			my $regexpscore = $self->CalcRegexpScore($subfield);
			if ($wordscore > 0) {
				$score += $wordscore;
				$multiplier += 1;
			} elsif ($regexpscore > 0) {
				$score += $regexpscore;
				$multiplier += 1;
			}
		}

		# Only count the dashes score if the amount of words between dashes
		# that has a score higher than 0 is at least half of the total amount
		# of words. So ca-santaanahub-cuda3-c8a-a-124 does not get any score
		# (only 'ca' and 'a' score, which is 2 out of 6 subfields), but
		# we-are-so-uuuuber-leet scores (only 'uuuuber' scores 0, so 4 out of
		# 5 subfields score more than 0).
		if ($multiplier >= 0.5 * scalar (@subfields)) {
			$hiref->{"dashesscore"} += $score * $multiplier;
		}
	}
}


# ---------------------------------------------------------------------
# Calculates and returns the word score of a field.

sub CalcWordScore {
	my ($self, $hostfield, $hiref) = @_;

	my $score = 0;
	my $lchostfield = lc($hostfield);

	if (defined( $self->{"wordvalue"}{$lchostfield} )) {
		$score = $self->{"wordvalue"}{$lchostfield};
	}

	$hiref->{"wordscore"}{$hostfield} = $score;

	return $score;
}

# ---------------------------------------------------------------------
# Calculates and returns the regexp score of a field.

sub CalcRegexpScore {
	my ($self, $hostfield, $hiref) = @_;

	my $score = 0;
	my @regexplist = keys %{$self->{regexpvalue}};

	# Walk throught the list of regexps and find the one with the highest
	# penalty score that this hostfield matches.
	foreach my $spamregexp (@regexplist) {
		if ($hostfield =~ /$spamregexp/) {
			if ($self->{regexpvalue}{$spamregexp} > $score) {
				$hiref->{"regexpmatches"}{$hostfield} = $spamregexp;
				$score = $self->{regexpvalue}{$spamregexp};
			}
		}
	}

	$hiref->{"regexpscore"}{$hostfield} = $score;

	return $score;
}


# ---------------------------------------------------------------------
# Calculates the penalty of the number of fields.
# First argument is a reference to a host info hash.

sub CalcNumFieldScore {
	my ($self, $hiref) = @_;
	my $pen = 0;

	my $numfields = $self->CalculateNumHostfields($hiref);

	$self->dprint("Calculating number of fields penalty for $numfields fields.\n", 1);

	if ($numfields == 3) { $pen = 5; }
	elsif ($numfields == 4) { $pen = 14; }
	elsif ($numfields == 5) { $pen = 35; }
	elsif ($numfields == 6) { $pen = 68; }
	elsif ($numfields > 6)  { $pen = 15 + ($numfields - 1) * ($numfields - 1) *
($numfields - 1); }
  
	return $hiref->{"numfieldscore"} = $pen;
}

# ---------------------------------------------------------------------
# Calculates the number of fields in the hostname.
# Reduce the number by 1 for each fields that corresponds to an entry
# in the fields datafile.

sub CalculateNumHostfields {
	my ($self, $hiref) = @_;
	my $numfields = scalar @{ $hiref->{"hostfields"} };

	# Check each field of the host.
	foreach my $field (@{ $hiref->{"hostfields"} }) {
		my $reduce = 0;

		if ($field =~ /^[0-9]+$/ && $field < 256) {
			$numfields--;
			next;
		}

		if ($field =~ /^[0-9]+-[0-9]+-[0-9]+-[0-9]+$/) {
			$numfields--;
			next;
		}

    	# Check each regexp to see if the field matches it.
    	foreach my $rf (@{$self->{rfields}}) {
			if ($field =~ /$rf/ && $reduce == 0) {
				$self->dprint("Reducing number of fields by 1 due to a match of $rf in $field.\n", 2);
				$reduce = 1;
				last;
			}
		}

		if ($reduce == 1) {
			$numfields--;
		}
	}

	return $numfields;
}

# ---------------------------------------------------------------------
# Calculates the penalty of the number of fields.
# First argument is a reference to a host info hash.

sub CalcFieldLengthScore {
	my ($self, $hiref) = @_;

	foreach my $field (@{ $hiref->{"hostfields"} }) {
		if (length($field) > 24) {
			$hiref->{"fieldlengthscore"} += length($field);
		}
	}
}

# ---------------------------------------------------------------------
# Calculates the penalty for the number of fields in this host.

sub CalcLooksLikeWordScore {
	my ($self, $hiref) = @_;
	$self->dprint("Checking if the fields look like words.\n", 1);

	# Only perform this check if there are at least 3 hostfields.
	if (scalar @{$hiref->{"hostfields"}} >= 3) {
		$self->dprint("More than 2 hostfields, checking...\n", 3);
    
		# As soon as any hostfield does not look like a word, return.
		foreach my $field (@{$hiref->{"hostfields"}}) {
			if (LooksLikeWord($self, $field) == 0) {
				return;
			}
		}

		# All hostfields look like words so apply the penalty.
		$hiref->{"lookslikewordscore"} = 20 * (scalar @{$hiref->{"hostfields"}} - 1);
	}

	return 0;
}

# ---------------------------------------------------------------------
# Calculates the penalty for having multiple identical fields

sub CalcRepeatScore {
	my ($self, $hiref) = @_;

	$hiref->{"repeatscore"} = 0;

	my %fieldcount;
	my $maxcount = 1;

	# First see how often each field is present.
	foreach my $field (@{ $hiref->{"hostfields"} }) {
		$fieldcount{"$field"}++;
		if ($fieldcount{"$field"} > $maxcount && $field !~ /^[0-9]+$/) {
			$maxcount = $fieldcount{"$field"};
		}
	}

	# Then determine the penalty.
	if ($maxcount > 1) {
		$hiref->{"repeatscore"} = 40 * ($maxcount - 1) * ($maxcount - 1);
	}
}


# ---------------------------------------------------------------------
# Calculates the penalty for having multiple one letter fields

sub CalcOneLetterScore {
	my ($self, $hiref) = @_;

	$hiref->{"oneletterscore"} = 0;
	my $oneletter = 0;

	# First see how many one-letter fields are present.
	foreach my $field (@{ $hiref->{"hostfields"} }) {
		if (length ($field) == 1 && $field !~ /[0-9]/) {
			$oneletter++;
		}
	}

	if ($oneletter > 1) {
		$hiref->{"oneletterscore"} = ($oneletter - 1) * 50;
	}
}


# ---------------------------------------------------------------------
# Calculates the total score, by creating a mathematical sum of the score
# and then eval()ing that.

sub CalcTotalScore {
	my ($self, $hiref) = @_;

	my $calculation = "";
	my ($wordscore, $regexpscore, $wrscore) = (0,0,0);
	my ($wordmultiplier, $regexpmultiplier, $wrmultiplier) = (0,0,0);
	my ($applywordmultiplier, $applyregexpmultiplier, $applywrmultiplier) = (0,0,0);
	$hiref->{"wordmultiplier"} = 1;
	$hiref->{"twordscore"} = 0;
	$hiref->{"regexpmultiplier"} = 1;
	$hiref->{"tregexpscore"} = 0;
	$hiref->{"wrmultiplier"} = 1;
	$hiref->{"wrscore"} = 0;

	if ($hiref->{"isblacklisted"}) {
		$self->dprint("Blacklisted. Setting base score to " . $hiref->{"blacklistscore"}, 2);
		$calculation = $hiref->{"blacklistscore"} . " + ";
	} elsif ($hiref->{"iswhitelisted"}) {
		$self->dprint("Whitelisted. Setting score to 0.", 2);
		$hiref->{"calculation"} = "0";
		$hiref->{"score"} = 0;
		return;
	}

	foreach my $field (@{ $hiref->{"hostfields"} }) {
		if (length($field) > 2 && $hiref->{"wordscore"}{$field} > 0) {
			$applywordmultiplier = 1;
			$applywrmultiplier = 1;
		}
		if (length($field) > 2 && $hiref->{"regexpscore"}{$field} > 0) { 
			$applyregexpmultiplier = 1;
			$applywrmultiplier = 1;
		}

		$self->dprint("Adding ".$hiref->{"wordscore"}->{$field}." for word $field.", 2); 
		$wordscore += $hiref->{"wordscore"}->{$field};
		if ($hiref->{"wordscore"}->{$field} > 0) {
			$wordmultiplier++;
		}

		$self->dprint("Adding ".$hiref->{"regexpscore"}->{$field}." for regexp $field.", 2); 
		$regexpscore += $hiref->{"regexpscore"}->{$field};
		if ($hiref->{"regexpscore"}->{$field} > 0) {
			$regexpmultiplier++;
		}

		# Calculate the total score: if this field has a word score,
		# add that; otherwise, add the regexp score, if present.
		if ($hiref->{"wordscore"}->{$field} > 0) {
			$wrmultiplier++;
			$wrscore += $hiref->{"wordscore"}->{$field};
		} elsif ($hiref->{"regexpscore"}->{$field} > 0) {
			$wrmultiplier++;
			$wrscore += $hiref->{"regexpscore"}->{$field};
		}

	}
	
	if ($wordmultiplier == 0) { $wordmultiplier = 1; }
	if ($regexpmultiplier == 0) { $regexpmultiplier = 1; }
	if ($wrmultiplier == 0) { $wrmultiplier = 1; }

	if ($applywordmultiplier == 0) { $wordmultiplier = 1; }
	if ($applyregexpmultiplier == 0) { $regexpmultiplier = 1; }
	if ($applywrmultiplier == 0) { $wrmultiplier = 1; }

	$hiref->{"wordmultiplier"} = $wordmultiplier;
	$hiref->{"twordscore"} = $wordscore;

	$hiref->{"regexpmultiplier"} = $regexpmultiplier;
	$hiref->{"tregexpscore"} = $regexpscore;

	$hiref->{"wrmultiplier"} = $wrmultiplier;
	$hiref->{"wrscore"} = $wrscore;

	my $calc2 = sprintf("(%d * %d) + %d + %d + %d + %d + %d + (0.5 * %d)",
		$wrmultiplier, $wrscore, 
		$hiref->{"numfieldscore"}, $hiref->{"fieldlengthscore"},
		$hiref->{"repeatscore"}, $hiref->{"oneletterscore"},
		$hiref->{"lookslikewordscore"}, $hiref->{"dashesscore"});
	$calculation = $calculation . $calc2;

	my $evalscore = $hiref->{"blacklistscore"} +
#		($wordmultiplier * $wordscore) + ($regexpmultiplier * $regexpscore) +
		($wrmultiplier * $wrscore) +
		$hiref->{"numfieldscore"} + $hiref->{"fieldlengthscore"} +
		$hiref->{"repeatscore"} + $hiref->{"oneletterscore"} +
		$hiref->{"lookslikewordscore"} + (0.5 * $hiref->{"dashesscore"});


	$hiref->{"score"} = int($evalscore);
	$hiref->{"calculation"} = $calculation;
}

# =====================================================================
# Tool functions.

# ---------------------------------------------------------------------
# Splits a hostname in two parts: the domain part and the part left
# of that. Will check if the host ends in a certain string, like
# "co.uk" or "com.au". If so, it will set the domain part to the
# rightmost 3 fields; if not, it will set the domain part to the
# rightmost 2 fields.
# Returns ($leftpart, $rightpart).

sub SplitHostname
{
	my ($self, $host) = @_;
	my $numdomainfields = 2;

	foreach my $tld (@{$self->{tlds}}) {
		my $pattern = $tld . "\$";
		if ($host =~ /$pattern/) {
			$numdomainfields = 3;
			last;
		}
 	}

	my @hostfields = split(/\./, $host);
	my $numfields = @hostfields;
	my @hostleftfields  = @hostfields[0..$numfields-$numdomainfields-1];
	my @hostrightfields = @hostfields[$numfields-$numdomainfields..$numfields-1];
  
	my $hostleft  = join(".", @hostleftfields);
	my $hostright = join(".", @hostrightfields);

	return ($hostleft, $hostright);
}


# ---------------------------------------------------------------------
# Checks to see if a string looks like a natural language word.

sub LooksLikeWord {
	my($self, $word) = @_;

	# if present in the wordlist, return 1
	if (defined $self->{wordvalue}{$word}) {
		return 1;
	}

	my ($consonants, $vowels, $numbers) = ($word, $word, $word);
	my($balc, $balv, $baln);

	$consonants =~ s/[0-9]//ig;
	$consonants =~ s/[aeiouy]//ig;
	$vowels =~ s/[^aeiouy]//ig;
	$numbers =~ s/[^0-9]//ig;

	$balc = length($consonants) / length($word);
	$balv = length($vowels) / length($word);
	$baln = length($numbers) / length($word);

	if (($balc >= 0.75 * $balv && $balc <= 2.1 * $balv) && $baln == 0.0) {
		return 1;
	}

	return 0;
}

# ---------------------------------------------------------------------
# Debug prints a message if the debug level is higher than the
# given level.

sub dprint {
	my ($self, $msg, $level) = @_;
	if (int($self->{debuglevel}) > int($level)) {
		print($msg . "\n");
	}
}

1;  # so the require or use succeeds

# ---------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (in docs/LICENSE); if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# ---------------------------------------------------------------------
#
# This package provides a class that calculates the dnsspam value
# of a hostname.
# The data to calculate this can be inserted via files and also modified
# via functions. Thus, you can create a $dnscalc object, fill it with
# data, and keep using it.
#
# ---------------------------------------------------------------------
#
# Usage of this class:
#
# use Dnsspam;
# my $spamcalc = SpamCalc->new();
# $spamcalc->load_datafiles("data");
# $spamcalc->add_blacklist("r0xxx.com", 60);
# my $hostname = "we.r0xxx.com";
# my $hostinfo = $spamcalc->get_info($hostname);
# print("Score of $hostname is " . $hostinfo->{"score} . ".\n");
#
# ---------------------------------------------------------------------
#
# Public functions:
#
# * load_datafiles($dir)
# Loads the datafiles in the given dir. If the dir is omitted, 
# "./data/" and "/etc/spamcalc/data/" are tried.
#
# * get_host_score($hostname)
# Calculates and returns the dnsspam score of $hostname.
# 
# * get_host_info($hostname)
# Calculates and returns the dnsspam info hash of $hostname. This is a
# hash with all kinds of data, like the score, whether it is black/
# whitelisted, how the score was calculated, etc.
# Returns a dnsspam info hash (see below).
#
# * get_field_score($field)
# Checks whether this field is present in the word hash or matches a
# regexp in the regexp hash, and if so, returns the associated score.
# If not, returns 0.
#
# * get_word_score($field)
# Returns the word score of $field.
#
# * get_regexp_score($field)
# Returns the regexp score of $field.
#
# * get_blacklist_score($hostname)
# Returns the blacklist score of $hostname. 0 means that the hostname is
# not blacklisted, and the higher the score, the more non-hierarchical the
# hostnames of this domain are.
# There is no maximum but 100 is normally the limit.
#
# * get_whitelist_score($hostname)
# Returns the whitelist score of $hostname. 0 means that the hostname is
# not whitelisted, and the higher the score, the more trusted the domain
# of this host is to make hierarchical hostnames.
# There is no maximum but 100 is normally the limit.
# 
# * add_word($word, $score, $lang = "uk")
# Adds this word to the internal score data.
#
# * add_regexp($regexp, $score)
# Adds this regexp to the internal score data.
#
# * add_blacklist($domain, $score)
# Adds this domain to the blacklist with the given base score.
#
# * add_whitelist($domain, $score = 100)
# Adds this domain to the whitelist with the given 'whiteness' score.
#
# * debuglevel($level)
# Sets the debuglevel to $level, then returns the debug level. If $level
# is omitted, just returns the debug level.
#
# The dnsspam info hash, returned by get_info, has these keys:
# hostname         - the hostname calculated
# hostpart         - the host part of the hostname
# hostfields       - an array with the field of the hostpart
# domainpart       - the domain part of the hostname
# score            - the dnsspam score
# calculation      - contains the string with the calculation done to reach
#                    the final spam score
# blacklisted      - whether the hostname is blacklisted (1 = yes, 0 = no)
# blacklistdomain  - the domain that was blacklisted
# blacklistscore   - the penalty obtained from the blacklist
# whitelisted      - whether the hostname is whitelisted (1 = yes, 0 = no)
# whitelistdomain  - the domain that was whitelisted
# whitelistscore   - the penalty obtained from the blacklist
# wordscore        - a hash with keys the fields of the hostpart and values
#                    the word scores of that field
# twordscore       - contains the sum of all these word scores
# wordmultiplier   - the multiplier which has been applied to the word
#                    scores of each field
# regexpscore      - a hash with keys the fields of the hostpart and values
#                    the regexp scores of that field
# regexpmatches    - a hash with keys the fields of the hostpart and values
#                    the regexp matched by that field
# tregexpscore     - contains the sum of all these regexp scores
# regexpmultiplier - the multiplier which has been applied to the regexp
#                    scores of each field
# numfieldscore    - penalty for the number of fields in the hostname
# fieldlengthscore - penalty for long fields
# repeatscore      - score for repeating fields
# dashesscore      - score for fields with dashes in them
# lookslikewordscore - 
#
# For a hostname like this.is.dnsspam.example.com, this would be:
# hostpart = "this.is.dnsspam";
# domainpart = "example.com";
# wordscore->{"this"} = 98;
# wordscore->{"is"} = 41;
# wordscore->{"dnsspam"} = 0;
#
# ---------------------------------------------------------------------

# -- EOF

