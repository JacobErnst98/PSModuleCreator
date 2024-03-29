<# 
 .SYNOPSIS 
 Returns a Module version number based on timestamp 

.DESCRIPTION 
 Returns a Module version number based on timestamp.
YearMonth.Day.HourMinute.Second 

.NOTES 
 Author: Mentaleak 

#> 
function get-ModuleVersion () {
 
Add-Type -AssemblyName System.Windows.Forms
	#$UpdateDate = $($RepoData.updated_at).split("T")[0].split("-")
	#$UpdateTime = $($RepoData.updated_at).split("T")[1].split(":")
	#$ModuleVersion = "$($UpdateDate[0])$($UpdateDate[1]).$($UpdateDate[2]).$($UpdateTime[0])$($UpdateTime[1]).$($UpdateTime[2].split(`"Z`")[0])"
	$time = (Get-Date)
	$UpdateDate = @("$($time.year.ToString("0000"))","$($time.Month.ToString("00"))","$($time.day.ToString("00"))")
	$UpdateTime = @("$($time.Hour.ToString("00"))","$($time.Minute.ToString("00"))","$($time.second.ToString("00"))")
	$ModuleVersion = "$($UpdateDate[0])$($UpdateDate[1]).$($UpdateDate[2]).$($UpdateTime[0])$($UpdateTime[1]).$($UpdateTime[2])"

	return $moduleVersion
}
