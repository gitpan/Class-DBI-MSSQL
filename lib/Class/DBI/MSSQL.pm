package Class::DBI::MSSQL;
our $VERSION = '0.01_01';

use strict;
use warnings;

use base qw(Class::DBI);

=head1 NAME

Class::DBI::MSSQL - Class::DBI for MSSQL

=head1 VERSION

version 0.01_01

 $Id: MSSQL.pm,v 1.5 2004/09/07 16:39:45 rsignes Exp $

=head1 SYNOPSIS

	use base qw(Class::DBI::MSSQL);

	# lots of normal-looking CDBI code

=head1 DESCRIPTION

This is just a simple subclass of Class::DBI;  it makes Class::DBI play nicely
with MSSQL, at least if DBD::ODBC is providing the connection.

Here are the things it changes:

=over 4

=item * use C<SELECT @@IDENTITY> to get last autonumber value

=item * use C<INSERT INTO table DEFAULT VALUES> for C<create({})>

=back

=cut

sub _auto_increment_value {
	my $self = shift;
	my $dbh  = $self->db_Main;

	my ($id) = $dbh->selectrow_array('SELECT @@IDENTITY');
	$self->_croak("Can't get last insert id") unless defined $id;
	return $id;
}

sub _insert_row {
	my $self = shift;
	my $data = shift;
	if (keys %$data) { 
		return $self->SUPER::_insert_row($data);
	} else {
		eval {
			my $sth     = $self->sql_MakeNewEmptyObj();
			$sth->execute;
			my @primary_columns = $self->primary_columns;
			$data->{ $primary_columns[0] } = $self->_auto_increment_value
				if @primary_columns == 1
				&& !defined $data->{ $primary_columns[0] };
		};
		if ($@) {
			my $class = ref $self;
			return $self->_croak(
				"Can't insert new $class: $@",
				err    => $@,
				method => 'create'
			);
		}
		return 1;
	}
}

__PACKAGE__->set_sql(MakeNewEmptyObj => 'INSERT INTO __TABLE__ DEFAULT VALUES');

=head1 WARNINGS

For one thing, there are no useful tests in this distribution.  I'll take care
of that, but right now this is all taken care of in the tests I've written for
subclasses of this class, and I don't have a lot of motivation to write new
tests just for this package.

Class::DBI's C<_init> sub has a line that reads as follows:

 if (@primary_columns == grep defined, @{$data}{@primary_columns}) {     

This will break MSSQL, and the line must be changed to:

 if (@$data{@primary_columns}
 	and @primary_columns == grep defined, @{$data}{@primary_columns}
 ) {

I can't easily subclass that routine, as it relies on lexical variables above
its scope.  I've sent a patch to Tony, which I expect to be in the next
Class::DBI release.

=head1 THANKS

...to Michael Schwern and Tony Bowden for creating and maintaining,
respectively, the excellent Class::DBI system.

...to Casey West, for his crash course on Class::DBI at OSCON '04, which
finally convinced me to just use the darn thing.

=head1 AUTHOR

Ricardo SIGNES, <C<rjbs@cpan.org>>

=head1 COPYRIGHT

(C) 2004, Ricardo SIGNES.  Class::DBI::MSSQL is available under the same terms
as Perl itself.

=cut

1;
