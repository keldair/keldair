package B::Hooks::OP::Check::EntersubForCV::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [],
          'deps' => [
                      'B::Hooks::OP::Check',
                      'B::Utils'
                    ],
          'libs' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/B/Hooks/OP/Check/EntersubForCV/Install/Files.pm") {
			$CORE = $_ . "/B/Hooks/OP/Check/EntersubForCV/Install/";
			last;
		}
	}

1;
