#!/usr/bin/perl
#-----------------------------------------------------------------------
# awssns2slack.pl
#
# Script that simplifies the AWS SNS publish API for processing by a
# corresponding AWS Lambda script which calls a Slack webhook.
#
#
#
#-----------------------------------------------------------------------
use strict;
use Getopt::Long;
use File::Basename;

sub usage {
   my $message = $_[0];
   if (defined $message && length $message) {
      $message .= "\n" unless $message =~ /\n$/;
   }

   my $command = $0;
   $command =~ s#^.*/##;

   print STDERR (
      $message,
      "usage: $command [-c color] [-d] [-e emoji] [-k key=value [...-k key=value]] [-m message] [-p pretext] [-s subject] [-t topic] [-u username] [-?|h]\n" .
      "Publish a message to AWS Simple Notification Service to be passed to Slack  webhook via AWS Lambda function." .
      "  c  Color of the Slack message. Defaultsa to #CCCCCC\n" .
      "  d  Displays the command that would be executed.\n" .
      "  e  Emoji. Must be from standard set as recognized by Slack.\n" .
      "  h  This help screen. Can also use -? as alias.\n" .
      "  k  Key/value pairs in key=value format. Multiples allowed.\n" .
      "  m  Message string.\n" .
      "  p  Pretext string.\n" .
      "  s  Subject string.\n" .
      "  t  Topic must be in AWS ARN format.\n" .
      "  u  Username for Slack post.\n" .
      "       ...\n" .
      "       ...\n" .
      "       ...\n"
   );

   die("\n")
}


# Where are we?
my $dirname = dirname(__FILE__);

# Default settings can be overridden in config files or command line parms
my ($_color, $_display, $_emoji, $_message, $_pretext, $_subject, $_topic, $_username);
my %_KVPAIRS;
my %_CHROME = (
  "emoji" => ":mailbox:",
  "color" => "#FF0000",
  "username" => "MQBert",
  );

{ # Import defaults from configuration files
  # Settings are cumulative. Homespace file overrides server-global
  # from /etc. File in script dir overrides homespace file.
  # Command line options supersede config files.
  my @files = ("/etc/aws/sns.config", glob("~/.aws/sns.config"), $dirname."/sns.config");
  my @cfgfile;
  for my $filename(@files){
    open FILE, $filename || continue;
    push @cfgfile, <FILE>;
    close FILE;
  }
  
  if ( @cfgfile > 0 ) {
    foreach my $line (@cfgfile) {
        chomp $line;

        next if $line =~ /^\s*$/ || $line =~ /^\s*#/ ;
        next if /^\s*#/;

        my @kv = split /\s*=\s*/, $line;
        if ($kv[0] =~ /^\s*emoji\s*$/i) {
            $kv[1] =~ s/[: '"{}]+//g;
            $_CHROME{'emoji'} = ":$kv[1]:";
        } elsif ($kv[0] =~ /^\s*color\s*$/i) {
            $kv[1] =~ s/[^0-9a-fA-F]+//g;
            $kv[1] =~ s/#//g;
            $_CHROME{'color'} = "#$kv[1]";
        } elsif ($kv[0] =~ /^\s*username\s*$/i) {
            $kv[1] =~ s/[: '"{}]+//g;
            $_CHROME{'username'} = "$kv[1]";
        } elsif ($kv[0] =~ /^\s*topic\s*$/i) {
            $kv[1] =~ s/[ '"{}]+//g;
            $_topic   = "$kv[1]";
        } elsif ($kv[0] =~ /^\s*pretext\s*$/i) {
            $kv[1] =~ s/[:'"{}]+//g;
            $_pretext = "$kv[1]";
        } elsif ($kv[0] =~ /^\s*subject\s*$/i) {
            $kv[1] =~ s/[:'"{}]+//g;
            $_subject = "$kv[1]";
        }
    }
  }
}

# Process supported command line options
my %options=();
GetOptions ('c=s' => sub { $_CHROME{'color'} = $_[1]; },
            'd'   => \$_display,
            'e=s' => sub { $_CHROME{'emoji'} = $_[1]; },
            'k=s' => \%_KVPAIRS,
            'm=s' => \$_message,
            'p=s' => \$_pretext,
            's=s' => \$_subject,
            't=s' => \$_topic,
            'u=s' => sub { $_CHROME{'username'} = $_[1]; },
) or usage("Invalid command line options.");

usage("The topic name must be specified.") unless defined $_topic;


my @_cmdargs=("/usr/local/bin/aws", "sns", "publish");
push(@_cmdargs, "--topic-arn", "'$_topic'") if defined $_topic;
push(@_cmdargs, "--subject", "'$_subject'") if defined $_subject;
push(@_cmdargs, "--message", "'$_message'") if defined $_message;

push(@_cmdargs, "--message-attributes");

my $_arg;
$_arg .= sprintf("'{");
$_arg .= sprintf("\"PRETEXT\":{\"DataType\":\"String\",\"StringValue\":\"%s\"},", $_pretext) if defined $_pretext;
if (%_KVPAIRS) {
  $_arg .= "\"KVPAIRS\":{\"DataType\":\"String\",\"StringValue\":\"";
  my $comma='';
  foreach my $key (sort (keys(%_KVPAIRS))) {
    $_arg .= "$comma$key=$_KVPAIRS{$key}";
    $comma=',';
  }
  $_arg .= "\"},";
}
$_arg .= sprintf("\"chrome\":{\"DataType\":\"String\",\"StringValue\":\"emoji=:%s:,username=%s,color=%s\"}", $_CHROME{'emoji'} =~ tr/://dr, $_CHROME{'username'}, $_CHROME{'color'});
$_arg .= "}'";
push(@_cmdargs, $_arg);
     
# Display or execute the command
my $_cmd=sprintf join(' ', (@_cmdargs)) . "\n";
print $_cmd                     if $_display;
system(("sh", "-c", $_cmd)) unless $_display;
