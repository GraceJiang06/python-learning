#!/app/perl/5.8.4/bin/perl
##############################################################################
# getErisData.pm
# Created: 2017.03.23 by 
# Function: This is Perl API to get configration Data.
##############################################################################
package getJsonData;
use strict;
use warnings;
use JSON;
use LWP::Simple;
use LWP::UserAgent;
use diagnostics;
use Switch;

our $web_base_url          = "";
our %web_base_url          = ();
$web_base_url{test_plans}  = "";
our $ENODEB = CONSTANT VALUE;
our $CABINET = CONSTANT VALUE;
our $TELNET = CONSTANT VALUE;
our $SWITCH = CONSTANT VALUE;
our $MDU = CONSTANT VALUE;
our $SYNCHRONIZATION = CONSTANT VALUE;
our $SOURCE = CONSTANT VALUE;

##############################################################################
# CONSTRUCTOR
# new ( <testplanName> )
# This is the cunstructor for this class
##############################################################################
sub new {
	my $class = shift;
	my (%params) = @_;
	my $self = {
	_baseUrl => $web_base_url{test_plans},
	_tpname => $params{tpname}
	};
	$self->{testPlanURL} = $self->{_baseUrl}.=$self->{_tpname};
	bless ($self, $class);	
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
	if ($response->is_error){
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
	switch($ci){
		case "$ENODEB" {
			die "Not find ENODEB attributes\n" unless $self->{testRbsHash};				
			$ref = $self->{testRbsHash};						
		}
		case "$CABINET" {
			die "Not find Cabinet attributes\n" unless $self->{testCabinetHash};
			$ref = $self->{testCabinetHash};
		}
		case "$TELNET" {			
			die "Not find telnet switch attributes\n" unless $self->{testSwitchHash};
			$ref = $self->{testSwitchHash};
		}
		case "$MDU" {
	                die "Not find master Du attributes\n" unless  $self->{testMduHash};
			$ref = $self->{testMduHash};
		}
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
#Get switch port.
#sightPort() -> rs232SwitchPort -> portNumber
sub getSwitchPort{
	#my($funcName) = shift;
	my($self) = @_;
	return $self->_getCiAttributes("$TELNET",['relation_list','params_ci_1','Port']);
}

##############################################################################
# getSwitchIp()
# returns the telnet switch IP.
##############################################################################
#Get switch IP address.
#sightHost() -> rs232SwitchPort -> telnetSwitch -> ipAddress -> ip
sub getSwitchIp{
	my($self) = @_;
	return $self->_getCiAttributes("$TELNET",['params','IP interface','value','0','IP','value']);
}

##############################################################################
# getBroadcastAddress()
# returns the ENODEB broadcast address.
##############################################################################
#Get RBS broadcast Address.
#broadcast() -> ethernetLink -> subnet -> broadcastAddress
sub getBroadcastAddress{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN subnet broadcast address','value']);
}

##############################################################################
# getNetmask()
# returns the ENODEB netmask name.
##############################################################################
#Get RBS Netmask name.
#netmask() -> ethernetLink -> subnet -> subnetMask -> name
sub getNetmask{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN subnet name','value']);
}

##############################################################################
# getIp()
# returns the ENODEB IP address.
##############################################################################
#Get RBS IP address.
#ip() -> ethernetLink, ip
sub getIp{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN IP address','value']);
}

##############################################################################
# getDefaultRouter()
# returns the ENODEB default router.
##############################################################################
#Get RBS defaultRouter.
#router() -> ethernetLink -> subnet -> defaultRouter
sub getDefaultRouter{
	my($self) = @_;
	return $self->_getCiAttributes("$MDU",['params','Site LAN subnet default router','value']);	
}

##############################################################################
# getTuSlot()
# returns the ENODEB tuslot.
##############################################################################
#Get RBS tuSlot.
#tuSlot() -> equipmentType? -> transmissionConfigurations, etSlot  #?
#tuSlot() -> equipmentType? -> tuSlot  #?
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
#Get RBS etSlot.
#etSlot() -> equipmentType? -> transmissionConfigurations, etSlot  #?
#etSlot() -> equipmentType? -> etResources, slot   
sub getEtSlot{
	my($self) = @_;	
	return $self->_getCiAttributes("$MDU",['params','Slot','value']);
	
}

##############################################################################
# getEtPort()
# returns the ENODEB etport.
##############################################################################
#Get RBS etPort  ????????????????????????????????????????????????????????????????
#4.3.5	Transmission configuration
#etPort() -> equipmentType? -> transmissionConfigurations, port  #?
#etPort() -> equipmentType? -> etResources, slot  #?
sub getEtPort{
	my($self) = @_;	
	return $self->_getCiAttributes("$MDU",['params','Port','value']);
}

##############################################################################
# getMpSlot()
# returns the ENODEB mp slot.
##############################################################################
#Get RBS mpSlot
#mpSlot() -> equipmentType? -> mpResources, slot  #?
sub getMpSlot{
	my($self) = @_;
        #return $self->_getRbsAttribValue(['params','MP list','value','0','Slot','value']);
        return '1';
}

##############################################################################
# getMpType()
# returns the ENODEB mp type.
##############################################################################
#Get RBS mptype
#mpType() -> duwConfiguration? -> mpResources, type, name  #?
sub getMpType{
	my($self) = @_;
	return "DUW";
        #return $self->_getRbsAttribValue(['params','MP type','value']);
}

##############################################################################
# getRbsType()
# returns the ENODEB type.
##############################################################################
#Get RBS type
#rbsType() -> nodeSubType, name
sub getRbsType{
	 my( $self)  = @_;
	 return $self->_getCiAttributes("$ENODEB",['params','Type','value']);	 
}

##############################################################################
# getRbsName()
# returns the ENODEB name.
##############################################################################
#Get RBS name
sub getRbsName{
	my( $self ) = @_;
	return $self->_getCiAttributes("$ENODEB",['name']);
}

##############################################################################
# getLnhPort()
# returns the ENODEB Link handler broadcast port.
##############################################################################
#Get RBS Link handler broadcast port
#lnhPort() -> linkHandlerBroadcastPort
sub getLnhPort{
	my( $self ) = @_;	
	#return $self->_getRbsAttribValue(['params','Link handler broadcast port','value']) || "";
	print "2DO linkhandler for multistandardnode ?";
	return  "";
}

##############################################################################
# getNodeType()
# returns the NODE type.
##############################################################################
#Get cabinet type
#nodeType() -> cabinetType, name
sub getNodeType{
	my( $self ) = @_;
	return $self->_getCiAttributes("$CABINET",['params','Product name','value']);
}

##############################################################################
# getNodeName()
# returns the NODE name.
##############################################################################
#Get cabinet name
sub getNodeName{
	my( $self ) = @_;
        #return $self->_getCabinetAttribValue(['name']);
        return $self->_getCiAttributes("$CABINET",['name']);
}

##############################################################################
# getTransmission()
# returns the ENODEB transmission type.
##############################################################################
#can't find
#transmission() -> equipmentType? -> transmissionLinks, controllerConfiguration, type, name #?
#transmission() -> equipmentType? -> etResources, type, name #?
sub getTransmission{
	my( $self ) = @_;	
	return $self->_getCiAttributes("$MDU",['params','Transmission type','value']);	
}

##############################################################################
# getTransport()
# returns the ENODEB transport.
##############################################################################
#can't find
#transport() -> transmissionConfigurations, name
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
	return $self->{testSNTPHash}->{'name'};


}
##############################################################################
# getNtpPrimaryServer()
# returns the primary ntp server.
##############################################################################
sub getNtpPrimaryServer{
	my ( $self ) = @_;
	return $self->{testPNTPHash}->{'name'};
}

##############################################################################
# DESTROY()
##############################################################################
sub DESTROY{
    my( $self ) = @_;
    print "$self->{class}::DESTROY called\n";
}
1;

my $getObj = getErisData->new(tpname=>'STP_NJRBS_233');
#print "$port \n";
#$getObj = getErisData_233->new(tpname=>'STP_NJRBS_233');

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
