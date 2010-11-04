package B::Hooks::OP::Annotation::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [],
          'deps' => [],
          'libs' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/B/Hooks/OP/Annotation/Install/Files.pm") {
			$CORE = $_ . "/B/Hooks/OP/Annotation/Install/";
			last;
		}
	}

1;
