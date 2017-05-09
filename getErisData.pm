##############################################################################
# getErisData.pm
# Created: 2017.03.23 by ehunjng
# Function: This is Perl API for Pre-Check to get Eris configration Data.
# 2017-05-03 by ehunjng
#   Changes: Function "getNodeLicense" added.
##############################################################################
package getErisData;
use lib '/xxxxxx/lib/perl5/site_perl/5.10.0'; #This is custom LIB_PATH
use strict;
use warnings;
use JSON;
use LWP::Simple;
use LWP::UserAgent;
use diagnostics;

our $web_base_url          = "";
our %web_base_url          = ();
$web_base_url{test_plans}  = "This is URL Restful API";

our $licensedir = "This is directory for storing license";
our $sites = "";
our %sites  = ();
$sites{linkoping}="";
$sites{nanjing}="";

our $ENODEB = "";
our $CABINET = "";
our $TELNET = "";
our $SWITCH = "";
our $MDU = "";
our $SYNCHRONIZATION = "";
our $SOURCE = "";

##############################################################################
# CONSTRUCTOR
# new ( <testplanName> )
# This is the cunstructor for this class
##############################################################################
sub new {
	my $class = shift;
	my %params = @_;
	my $self = {
	_baseUrl => $web_base_url{test_plans},
	_tpname => $params{tpname},
	_opsite => $params{site},
	_licensedir => $licensedir
	};
	bless ($self, $class);
	if (lc($self->{_opsite}) eq "li"){
		$self->{_licensedir} = $self->{_licensedir}.$sites{linkoping}."/"
	}
	if (lc($self->{_opsite}) eq "nj") {
		$self->{_licensedir} = $self->{_licensedir}.$sites{nanjing}."/"	
	}
	$self->{testPlanURL} = $self->{_baseUrl}.=$self->{_tpname};
	$self->{_cfg} = $self->{_tpname}.".cfg";
        $self->{_licensefile} = $self->{_licensedir}.$self->{_tpname}."/".$self->{_cfg};
		
	$self->_setCisAttributes();
	$self->{class} = $class;
	return $self;
}

##############################################################################
# _setCisAttributes()
# set attributes to CI hash attribute:
#  testRbsHash 
#  testCabinetHash 
#  testSwitchHash 
#  testMduHash 
#  testPNTPHash 
#  testSNTPHash
##############################################################################
sub _setCisAttributes{
	my($self) = @_;
	$self->{testPlan} = $self->_getResponseContent($self->{testPlanURL})->{items};
	foreach ( @{ $self->{testPlan} }){
		die "Not find key ci_type in element $->{'ci_type'} $self->{testPlanURL}" unless $_->{'ci_type'};
		if ($_->{'ci_type'} =~ /$ENODEB/){
			$self->{testRbsHash} = $_;
		}
		if ($_->{'ci_type'} =~ /$CABINET/){
			$self->{testCabinetHash} = $_;
		}
		if ($_->{'ci_type'} =~ /$TELNET/ and $_->{'ci_type'} =~ /$SWITCH/){
			$self->{testSwitchHash} = $_;
		}
		if ($_->{'ci_type'} =~ /$MDU/ and $_->{params}->{Master}->{value} =~ /true/){
			$self->{testMduHash} = $_;
			my $test = scalar($_->{params}->{Master}->{value});
		}
		if ($_->{'ci_type'} =~ /$SYNCHRONIZATION/ and $_->{'ci_type'} =~ /$SOURCE/){             	
			if (exists($_->{relation_list}->[0]->{params_ci_1}->{Value}->{0}->{'Primary sync ref'}) 
			and $_->{relation_list}->[0]->{params_ci_1}->{Value}->{0}->{'Primary sync ref'}->{value} =~ /true/){
				$self->{testPNTPHash} = $_; 
			}
			else              	
			{
				$self->{testSNTPHash} = $_;  
			}
		}		
	}
	return $self;
}

##############################################################################
# _getResponseContent()
# returns the testplan data which is json format.
##############################################################################
sub _getResponseContent{
	my( $self,$URL) = @_;
	my $ua = LWP::UserAgent->new(
			 protocols_allowed => [ 'http', 'https' ],
			 timeout           => 30,
			 ssl_opts => { verify_hostname => 0 }
			 );
	my $retval = {};
	my $json = JSON->new->utf8;
	my $response = $ua->get($URL);
	if ($response->{is_error}){
		print "Failed to get testplan data by $self->{testPlanURL}\n";
		die $response->message;
	} 
	my $content = $response->content;
	$retval = $json->decode($content);
	return $retval;
}

##############################################################################
# _getCiAttributes( <ciName>, [attrib,attrib,...] )
# returns the value of attribute
##############################################################################
sub _getCiAttributes{
	my ( $self, $ci, $attribs ) = @_;
	#print "$ci\n";
	#print "$attribs\n";
	my $ref = "";	

	if($ci =~ /$ENODEB/){
		die "Not find ENODEB attributes\n" unless $self->{testRbsHash};				
		$ref = $self->{testRbsHash};						
	}
	if($ci =~ /$CABINET/){	
		die "Not find Cabinet attributes\n" unless $self->{testCabinetHash};
		$ref = $self->{testCabinetHash};
	}
		
	if($ci =~ /$TELNET/){			
		die "Not find telnet switch attributes\n" unless $self->{testSwitchHash};
		$ref = $self->{testSwitchHash};
	}
	if($ci =~ /$MDU/){
		die "Not find master Du attributes\n" unless  $self->{testMduHash};
		$ref = $self->{testMduHash};
	}
	foreach ( @{ $attribs } ) {
		$ref = $ref->[ 0 ] if ( ref( $ref ) eq 'ARRAY' );		
		$ref = $ref->{ $_ }; 
	}
	return $ref;
}

##############################################################################
# getSwitchPort()
# returns the telnet switch port.
##############################################################################
sub getSwitchPort{
	my($self) = @_;
	return $self->_getCiAttributes("$TELNET",['relation_list','params_ci_1','Port']);
}

##############################################################################
# getSwitchIp()
# returns the telnet switch IP.
##############################################################################
sub getSwitchIp{
	my($self) = @_;
	return $self->_getCiAttributes("$TELNET",['params','IP interface','value','0','IP','value']);
}

##############################################################################
# getBroadcastAddress()
# returns the ENODEB broadcast address.
##############################################################################
sub getBroadcastAddress{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN subnet broadcast address','value']);
}

##############################################################################
# getNetmask()
# returns the ENODEB netmask name.
##############################################################################
sub getNetmask{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN subnet name','value']);
}

##############################################################################
# getIp()
# returns the ENODEB IP address.
##############################################################################
sub getIp{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN IP address','value']);
}

##############################################################################
# getDefaultRouter()
# returns the ENODEB default router.
##############################################################################
sub getDefaultRouter{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN subnet default router','value']);	
}

##############################################################################
# getTuSlot()
# returns the ENODEB tuslot.
##############################################################################
sub getTuSlot{
	my($self) = @_;
	#return $self->_getRbsAttribValue(['params','Primary TU slot','value']);
        return $self->_getCiAttributes("$MDU",['params','Slot','value']);
	#return "?";
}

##############################################################################
# getEtSlot()
# returns the ENODEB etslot.
############################################################################## 
sub getEtSlot{
	my($self) = @_;	
	return $self->_getCiAttributes("$MDU",['params','Slot','value']);
	
}

##############################################################################
# getEtPort()
# returns the ENODEB etport.
##############################################################################
sub getEtPort{
	my($self) = @_;	
	return $self->_getCiAttributes("$MDU",['params','Port','value']);
}

##############################################################################
# getMpSlot()
# returns the ENODEB mp slot.
##############################################################################
sub getMpSlot{
	my($self) = @_;
        #return $self->_getRbsAttribValue(['params','MP list','value','0','Slot','value']);
        return '1';
}

##############################################################################
# getMpType()
# returns the ENODEB mp type.
##############################################################################
sub getMpType{
	my($self) = @_;
	return "DUW";
        #return $self->_getRbsAttribValue(['params','MP type','value']);
}

##############################################################################
# getRbsType()
# returns the ENODEB type.
##############################################################################
sub getRbsType{
	 my( $self)  = @_;
	 return $self->_getCiAttributes("$ENODEB",['params','Type','value']);	 
}

##############################################################################
# getRbsName()
# returns the ENODEB name.
##############################################################################
sub getRbsName{
	my( $self ) = @_;
	return $self->_getCiAttributes("$ENODEB",['name']);
}

##############################################################################
# getLnhPort()
# returns the ENODEB Link handler broadcast port.
##############################################################################
sub getLnhPort{
	my( $self ) = @_;	
	#return $self->_getRbsAttribValue(['params','Link handler broadcast port','value']) || "";
	#print "2DO linkhandler for multistandardnode ?";
	return  "";
}

##############################################################################
# getNodeType()
# returns the NODE type.
##############################################################################
sub getNodeType{
	my( $self ) = @_;
	return $self->_getCiAttributes("$CABINET",['params','Product name','value']);
}

##############################################################################
# getNodeName()
# returns the NODE name.
##############################################################################
sub getNodeName{
	my( $self ) = @_;
        #return $self->_getCabinetAttribValue(['name']);
        return $self->_getCiAttributes("$CABINET",['name']);
}

##############################################################################
# getTransmission()
# returns the ENODEB transmission type.
##############################################################################
sub getTransmission{
	my( $self ) = @_;	
	return $self->_getCiAttributes("$MDU",['params','Transmission type','value']);	
}

##############################################################################
# getTransport()
# returns the ENODEB transport.
##############################################################################
sub getTransport{
	my( $self ) = @_;
	return $self->_getCiAttributes("$MDU",['params','Port','value']) || "";
}

##############################################################################
# getNtpSecondaryServer()
# returns the secondary ntp server.
##############################################################################
sub getNtpSecondaryServer{
	my ( $self ) = @_;
	if (exists( $self->{testSNTPHash}->{'name'})){
		return $self->{testSNTPHash}->{'name'};
	}
}
##############################################################################
# getNtpPrimaryServer()
# returns the primary ntp server.
##############################################################################
sub getNtpPrimaryServer{
	my ( $self ) = @_;
	if (exists($self->{testPNTPHash}->{'name'})){
		return $self->{testPNTPHash}->{'name'};
        }
}
##############################################################################
# getNodeLicense()
# returns the name of license file.
# It only returns the license file which is the newest.
##############################################################################
sub getNodeLicense{
	my ( $self ) = @_;
	my @expireDateArray;
	my %licenseHash;
	#validate the directory and license file is valid or not.
	if ( ! -d $self->{_licensedir}){
		die "license directory $self->{_licensedir} doesn't exist.";
	}	
	if ( ! -f $self->{_licensefile}){
		die "the config file $self->{_licensefile} doesn't exist.";
	}	
	if ( -z $self->{_licensefile}){
		die "the config file $self->{_licensefile} is empty.";	
	}
	
	#open STPNAME.cfg and deal with the file line by line.	
        open(my $FILE,"<",$self->{_licensefile})||die"can not open the file: $!\n";
	my @linelist = <$FILE>;
	my $linecount = @linelist;
	if ( $linecount lt 2){
	    die "the config file $self->{_licensefile} is not valid, it should contains 2 lines at least.";
	}
	foreach my $eachline(@linelist){
	    my @tmpArray = split(/,/,$eachline);
	    if ($tmpArray[0] eq "TEST_CONFIGURATION_NAME"){
	    	next;
	    }
	    push(@expireDateArray,$tmpArray[8]);
	    $licenseHash{$tmpArray[8]} = $tmpArray[2];
	}
	close $FILE;
	my @sorted_Array = sort(@expireDateArray);
	return  $licenseHash{pop(@sorted_Array)};
}
##############################################################################
# DESTROY()
##############################################################################
sub DESTROY{
    my( $self ) = @_;
    print "$self->{class}::DESTROY called\n";
}
1;

=comment:this is for test and usage
my $getObj = getErisData->new(tpname=>'NJRBS_268',site=>"nj");

print "0_licensefile:\n";
my $licenseFile = $getObj->getNodeLicense();
print "0_licensefile:$licenseFile\n\n";

print "1_sightPort() -> rs232SwitchPort -> portNumber\n";
my $switchPort = $getObj->getSwitchPort();
print "1_switchPort:$switchPort\n\n";

print "2_sightHost() -> rs232SwitchPort -> telnetSwitch -> ipAddress -> ip\n";
my $SwitchIp = $getObj->getSwitchIp();
print "2_switchIp:$SwitchIp\n\n";

print "3_broadcast() -> ethernetLink -> subnet -> broadcastAddress\n";
my $BroadcastAddress = $getObj->getBroadcastAddress();
print "3_BroadcastAddress:$BroadcastAddress\n\n";

print "4_netmask() -> ethernetLink -> subnet -> subnetMask -> name\n";
my $Netmask = $getObj->getNetmask();
print "4_Netmask:$Netmask\n\n";

print "5_ip() -> ethernetLink, ip\n";
my $IP = $getObj->getIp();
print "5_IP:$IP\n\n";

print "6_router() -> ethernetLink -> subnet -> defaultRouter\n";
my $DefaultRouter = $getObj->getDefaultRouter();
print "6_DefaultRouter:$DefaultRouter\n\n";

print "7_tuSlot() -> equipmentType? -> tuSlot  #?\n";
my $TuSlot = $getObj->getTuSlot();
print "7_TuSlot:$TuSlot\n\n";

print "8_etSlot() -> equipmentType? -> etResources, slot\n";
my $EtSlot = $getObj->getEtSlot();
print "8_EtSlot:$EtSlot\n\n";

print "9_etPort() -> equipmentType? -> etResources, slot  #?\n";
my $EtPort = $getObj->getEtPort();
print "9_EtPort:$EtPort\n\n";

print "10_mpSlot() -> equipmentType? -> mpResources, slot  #?\n";
my $MpSlot = $getObj->getMpSlot();
print "10_MpSlot:$MpSlot\n\n";

print "11_mpType() -> duwConfiguration? -> mpResources, type, name  #? \n";
my $MpType = $getObj->getMpType();
print "11_MpType:$MpType\n\n";

print "12_rbsType() -> nodeSubType, name\n";
my $RbsType = $getObj->getRbsType();
print "12_RbsType:$RbsType\n\n";

print "13_lnhPort() -> linkHandlerBroadcastPort??\n";
my $LnhPort = $getObj->getLnhPort();
print "13_LnhPort:$LnhPort\n";

my $RbsName = $getObj->getRbsName();
print "14_RbsName:$RbsName\n\n";

print "15_nodeType() -> cabinetType, name\n";
my $NodeType = $getObj->getNodeType();
print "15_NodeType:$NodeType\n";

my $NodeName = $getObj->getNodeName();
print "16_NodeName:$NodeName\n\n";

print "17_ntpPrimaryServer() -> primaryTimeServer\n";
my $ntpPrimary= $getObj->getNtpPrimaryServer();
print "17_ntpPrimary:$ntpPrimary\n\n";

print "18_ntpSecondaryServer() -> secondaryTimeServer\n";
my $ntpSecond = $getObj->getNtpSecondaryServer();
print "18_ntpSecond:$ntpSecond\n\n";

print "19_transmission() -> equipmentType? -> transmissionLinks, controllerConfiguration, type, name #?\n";  
my $transmission = $getObj->getTransmission();
print "19_transmission:$transmission\n\n";

print "20_transport() -> transmissionConfigurations, name\n";
my $transport = $getObj->getTransport();
print "20_transport:$transport\n\n";
=comment: this is for test and usage
