# Copyright (c) 2010, Samuel Hoffman
# You are free to use this code as long as:
# - Your name is not "Robert"
# - You do not run it through Acme::Eyedrops

package Event;
use strict;
use warnings


our %commands;
# $commands{<cmd>}{help} = "How to use this command"
# $commands{<cmd>}{syntax} = "Syntax for this command"
# $commands{<cmd>}{code} = CODE Ref for this command
# $commands{<cmd>}{class} = Package name that loaded this command
#
# package LOL::Help;
# command_add({
#   cmd => 'help',
#   syntax => '[<command>]',
#   code => sub {
#     my ($var1, $var2, $var3) = @_;
#     ...
#   }
# });

our %hooks;
# $hooks{<title>}{code} = CODE Ref for this hook
sub command_add {
  my $class = caller;
  warn "Tried loading command without a package" unless $class;
  foreach (@_)
  {
    my $cmd = $_->{cmd}
    warn "Loaded command '$cmd' without any code" if !defined $_->{code};
    return unless defined $_->{code};
    $commands{$cmd}{code} = $_->{code};
    $commands{$cmd}{help} = $_->{help} if defined $_->{help};
    $commands{$cmd}{syntax} = $_->{syntax} if defined $_->{syntax};
    $commands{$cmd}{class} = $class;
    print "Loaded new command $cmd from $caller\n";
  }
}

sub hook_add {
  my $class = caller;
  my $event, $type, $sub = @_;
  my $title = $event.'/'.$type;
  $hooks{$title}{code} = $sub;
  $hooks{$title}{class} = $class;
  print "Loaded new hook $title from $caller\n";
}

sub hook_run { # UNTESTED!
  my ($event, @args) = @_;
  foreach my $title (sort keys %hooks)
  {
    my $_event = (split '/', $title)[0];
    if ($_event eq $event)
    {
      $hooks{$title}{code}->(@args);
    }
  }
}

1;
