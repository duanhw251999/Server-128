package Helper;

use List::Util qw(max min);
use File::Basename;
use Net::FTP;


my $AUTO_HOME = $ENV{"AUTO_HOME"}; 
my $LOGON_FILE = "${AUTO_HOME}/etc/EDA_LOGIN_ODSKF";
my $LOGON_FILE_GEN = "${AUTO_HOME}/ETC/EDA_FTP_GEN";


sub Get_Time{
	#print " == 0 == 	Start Get_Time :: 获取当前日期\n";	
	#flag: 1:获取当前日期+时间,2:#获取当前日期,3:获取当前时间
	my ($flag)=@_;                                                
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	$year += 1900;
	$mon+=1;
	if ($mon < 10)  { $mon="0".$mon;  } else { $mon=$mon;}
	if ($mday < 10) { $mday="0".$mday; } else { $mday=$mday; }
	my $theSysTime1=sprintf("%4d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$sec); #获取当前日期+时间
	my $theSysTime2=sprintf("%4d-%02d-%02d %02d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec); #获取当前日期+时间
	my $Sys_Date=sprintf("%4d-%02d-%02d",$year,$mon,$mday);    #获取当前日期 YYYY-MM-DD
	my $Sys_Time=sprintf("%02d:%02d:%02d",$hour,$min,$sec);    #获取当前时间
	my $SysDate=sprintf("%4d%02d%02d",$year,$mon,$mday);    #获取当前日期    YYYYMMDD
	#print " == 1 == 	End Get_Time\n";
	if($flag == 4){return ($theSysTime1);}
	if($flag == 1)
		{return ($theSysTime2);}
	else
		{
			if($flag == 2)
			{return ($Sys_Date);}
			else
			{
				if($flag == 3)
				{return ($SysDate);}
				else
				{return ($Sys_Time);}
			}
		}	                                                                               
}

sub getFtpAccess{
	my ($ftplist,$Ftp_User,$Ftp_Pass);
	  unless ( open(LOGONFILE_GEN, "${LOGON_FILE_GEN}") ) {
	  print "Open Logon file fail, LOGON_FILE=${LOGON_FILE_GEN}\n";
	  exit(253);
	}
	$ftplist = <LOGONFILE_GEN>;
	
	close(LOGONFILE_GEN);
	
	# Get the decoded logon string
	$ftplist = `${AUTO_HOME}/bin/IceCode.exe "$ftplist"`;
	my @ftplist = split(/ /,$ftplist);
	chop($ftplist[1]);
	($Ftp_User,$Ftp_Pass)=split(/,/,$ftplist[1]);	
  return  ($Ftp_User,$Ftp_Pass);
}

sub Get_Ftp_Connection{
	my $ftp;
  my $connect_times = 0;
  my ($LOGON_FILE_GEN,$Ftp_Host)=@_;
  my ($ftplist,$Ftp_User,$Ftp_Pass);
  open(LOGONFILE_GEN, "${LOGON_FILE_GEN}") ||die "找不到对应的配置文件!\n";
  $ftplist = <LOGONFILE_GEN>;
  close(LOGONFILE_GEN);

  # Get the decoded logon string
  $ftplist = `${AUTO_HOME}/bin/IceCode.exe "$ftplist"`;
  my @ftplist = split(/ /,$ftplist);
  chop($ftplist[1]);
  ($Ftp_User,$Ftp_Pass)=split(/,/,$ftplist[1]);
  print  "connectting to ftp server $Ftp_Host !\n";  
  while(!($ftp = Net::FTP->new($Ftp_Host))){
    print  "open ftp server $Ftp_Host failed\n";
    sleep(8);
    $connect_times++;
    if ($connect_times>=3)
    {
      print "连接${Ftp_Host}失败\n";
      print  "open ftp server $Ftp_Host failed over 3 times!\n";
      return "";  
    }
  }
  my $rc = $ftp->login($Ftp_User,$Ftp_Pass);
  print $ftp->message."\n";
  unless($rc){
    print "FTP用户名密码错误!\n";
    print  "incorrect usr/passwd:$Ftp_User/$Ftp_Pass\n";
    print  $ftp->message . "\n";
    #exit(1);
    $ftp->quit();
    return "";
  }
  
  #$ftp->type("bin");
  $ftp->binary;
  print  "connectted to ftp server $Ftp_Host successfully!\n";  
  return $ftp;
}
#=================================================  
sub Get_File_Path{
	my $theTime=Get_Time(1);
	print "$theTime Start Get_File_Path :: 读取文件路径\n";
	open(PATH,$Conf_Path);
	my $Path_Str;	
	my @Paths=<PATH>;
	foreach my $Load(@Paths)
	{
		$Load=~s/\s//g;
		if($Load=~/\w+/gi)		
		{
		chomp($Load);
	    $Path_Str="$Path_Str"."$Load"."|";
	  }
	}
	$theTime=Get_Time(1);	
	print "$theTime End Get_File_Path\n";
	return $Path_Str;
}

sub processArgv{
	 my $str=shift @_;
   my @splitstr=();
   while($str=~/\_/g){
		my $p=pos($str);
		push(@splitstr,$p);
	}
	my $max_val=max @splitstr;
	my $min_val=min @splitstr;
	my @arr=split (/\_/ ,$str);
	my ($sys,$path,$txt_date)=($arr[0],substr ($str,($min_val),($max_val-5)),substr(${str},length(${str})-12, 8));
	return ($sys,$path,$txt_date);
}


sub Get_PARALLEL{
  	my ($dbh)=@_;
  	my $sqlstr="select sum(decode(PARALLEL_NAME, 'PARALLEL_MIN', PARALLEL_VALUE)),". 
                "sum(decode(PARALLEL_NAME, 'PARALLEL_NORMAL', PARALLEL_VALUE)), ".
                "sum(decode(PARALLEL_NAME, 'PARALLEL_MAX', PARALLEL_VALUE))".
                 "from ODSPMART.T_DIM_PARALLEL ORDER BY PARALLEL_VALUE";
  	my $stmt = $dbh->prepare($sqlstr) || die "Error: $DBI::errstr\n";
  	$stmt->execute()                    || die "Error: $DBI::errstr\n";
  	my@PARALLEL =$stmt->fetchrow();
  	$PARALLEL_MAX = $PARALLEL[2];
    $PARALLEL_NORMAL = $PARALLEL[1];
    $PARALLEL_MIN = $PARALLEL[0];
    print "\PARALLEL_MAX:$PARALLEL_MAX\n\PARALLEL_NORMAL:$PARALLEL_NORMAL\n\PARALLEL_MIN:$PARALLEL_MIN\n";
	}	
	
sub modifySerail{
	my ($name,$cdate,$ddate,$resendno,$pcno,$serial,$prov,$ftype)=split(/\./,@_[0]);
	$serial=sprintf("%03d",$serial);
	return $name.".".$cdate.".".$ddate.".".$resendno.".".$pcno.".".$serial.".".$prov.".".$ftype;
}
sub countRow{
	my $file_path=shift @_;
	open(FILE ,$file_path); 
	my $lines_counter = 0;  
	while(<FILE>)
	{
		$lines_counter += 1; 
	}
	close FILE;
	return ($lines_counter);
}

sub dataBaseStr{
	my $os = $^O;
  my $ora_odbc=$ENV{"AUTO_ORADSN"};
  if (!defined($ora_odbc)){
    $ora_odbc="GSEDA";
  }
  $os =~ tr [A-Z][a-z];
  my $DB_Connect = "dbi:Oracle:GSEDA";

  unless ( open(LOGONFILE_H, "${LOGON_FILE}") ) {
    print "Open Logon file fail, LOGON_FILE=${LOGON_FILE}\n";
    exit(253);
  }
  my $list = <LOGONFILE_H>;
  
  close(LOGONFILE_H);

  # Get the decoded logon string
  $list = `${AUTO_HOME}/bin/IceCode.exe "$list"`;
  my @list = split(/ /,$list);
  chop($list[1]);
  my ($orauser,$passwd)=split(/,/,$list[1]);
  my $LOGON_STR="$orauser\/$passwd\@GSEDA";
  return ($LOGON_STR,$DB_Connect,$orauser,$passwd);
}

1;
