package CatalystX::Syntax::Action;

use strict;
use warnings FATAL =>'all';

use parent 'Devel::Declare::MethodInstaller::Simple';

our $VERSION = '0.01';

sub import {
  my $class = shift;
  my $caller = caller;
  my %opts = $class->_set_defaults($caller,@_);
  $class->install_methodhandler(name=>'action', %opts);
}

sub _set_defaults {
  my ($class, $caller, %opts) = @_;
  $opts{into} ||= $caller;
  $opts{invocant} ||= '$self';
  $opts{context} ||= '$ctx';
  return %opts;
}

sub parse_proto {
  my $self = shift;
  my ($proto) = @_;
  $proto ||= '';
  $proto =~ s/[\r\n]//g;
  my $invocant = $self->{invocant};
  my $context = $self->{context};

  $invocant = $1 if $proto =~ s{^(\$\w+):\s*}{};

  my $inject = "my ${invocant} = shift; my ${context} = shift;";
  $inject .= "my ($proto) = \@_;" if defined $proto and length $proto;

  return $inject;
}

1;

=head1 NAME

CatalystX::Syntax::Action - Semantically meaningfull Catalyst Actions with signatures

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use Moose;
    use namespace::autoclean;

    extends 'Catalyst::Controller';

    action my_action($arg) : Path('my_special_action') Args(1)
    {
        $ctx->response->body('Look ma, no "my ($self, $ctx, $arg) = @_;"
    }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This module uses a bit of lightweight L<Devel::Declare> magic to add a new
keyword into your L<Catalyst::Controller> called C<action>.  It works just
like L<Method::Signatures::Simple>, except it also C<shift>s off the C<context>
argument, saving you a bit of boilerplate.  Additionally you might find that
calling an action 'action' more meaningfully separates it visually from methods
in your L<Catalyst::Controller> that are normal methods.

The test suite has a working example of this for your review.

=head1 CAVEATS

When using L<Moose> style method modifiers you'll need to drop back to using
'classic' Perl subroutine syntax, or something like L<Function::Parameters>
since method modifiers change the incoming arguments.  So for example:

    action myaction :path('foo') Args(1) { ... }

Would need to be modified (as say in a ControllerRole) using:

    use Moose::Role;

    around 'myaction', sub {
      my ($orig, $self, $ctx, @args) = @_;
      ...
    };

This is because we can't detect the fact that C<$orig> as the first argument is
a coderef to the modified method rather than a blessed reference to the instance
of L<Catalyst::Controller>.  If you are attached to the method signatures in
your code you could use L<Function::Parameters>:

    use Moose::Role;
    use Function::Parameters;

    around 'myaction', fun($orig, $self, $ctx, @args) {
      ...
    };

=head1 use syntax

You can use the alternative L<syntax> module to activate this extention.  This
would allow you to easily and cleanly enable multiple extenstions.  For example:

    package MyApp::Web::Controller::Root;

    use Moose;
    use syntax 'method', 'action';

    extends 'Catalyst::Controller'l

    action myaction { ... }
    method mymethod { ...}

    __PACKAGE__->meta->make_immutable;

=head1 THANKS

I basically just copied the known working code in L<Method::Signatures::Simple>
to make this.  My thanks to the authors and maintainers!

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<Catalyst>, L<Method::Signatures::Simple>, L<syntax>, L<Devel::Declare>

=head1 COPYRIGHT & LICENSE

Copyright 2011, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
