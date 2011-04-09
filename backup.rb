#!/usr/bin/ruby
#
# Backup script by Jack Senechal

# configuration variables
@source        = "/home/jack/Documents/"
@destination   = "/home/jack/Backups/Documents"
@end_of_week   = "Friday"
@rsync_command = "rsync -av --delete"
@tar_command   = "tar -cjvf"

# not configuration variables
@day = `date +%A`.strip!

# run this every day
def daily_backup()
  # rsync the source to the current day's backup folder
  `#{@rsync_command} "#{@source}/" "#{@destination}/daily/#{@day}"`
  # sanity check: make a symlink to the latest for quick visual confirmation
  `rm "#{@destination}/daily/latest"` if File.exists?("#{@destination}/daily/latest")
  `ln -s "#{@day}" "#{@destination}/daily/latest"`
end

# run this BEFORE you do the daily_backup() for the current day
def weekly_backup()
  # define weekly backup names
  two   = "#{@destination}/weekly/two_weeks_ago"
  three = "#{@destination}/weekly/three_weeks_ago"
  four  = "#{@destination}/weekly/four_weeks_ago"
  tmp   = "#{@destination}/weekly/tmp"
  # shuffle 'em around
  `mv "#{four}"  "#{tmp}"`   if File.exists?(four)
  `mv "#{three}" "#{four}"`  if File.exists?(three)
  `mv "#{two}"   "#{three}"` if File.exists?(two)
  `mv "#{tmp}"   "#{two}"`   if File.exists?(tmp)
  # rsync last week's backup for today to weekly backup number two
  command = "#{@rsync_command} '#{@destination}/daily/#{@day}/' '#{two}'"
  `#{command}`
end

def monthly_backup()
  date = `date +%F`.strip!
  tar_file = "#{@destination}/monthly/#{date}.tar.bz2"
  todays_backup = "#{@destination}/daily/latest/"
  dir = `pwd`.strip!
  `cd "#{todays_backup}" && #{@tar_command} "#{tar_file}" * && cd "#{dir}"`
end

# try to mount the destination drive if it's not there
def mount_destination()
  # not implemented!
end

# make sure all everything looks ok before proceeding
def sanity_check()
  # exit with error message if we can't find the source
  abort("Can't find the source! (#{@source})") if !File.exists?(@source)
  # try to mount the destination if it's not there already,
  # and exit with error if we still can't find it
  mount_destination() if !File.exists?(@destination)
  abort("Can't find the destination! (#{@destination})") if !File.exists?(@destination)
  # create basic directories
  if !File.exists?("#{@destination}/daily")
    `mkdir -p "#{@destination}/daily/Monday" "#{@destination}/daily/Tuesday" "#{@destination}/daily/Wednesday" "#{@destination}/daily/Thursday" "#{@destination}/daily/Friday" "#{@destination}/daily/Saturday" "#{@destination}/daily/Sunday"`
  end
  if !File.exists?("#{@destination}/weekly")
    `mkdir -p "#{@destination}/weekly/two_weeks_ago" "#{@destination}/weekly/three_weeks_ago" "#{@destination}/weekly/four_weeks_ago"`
  end
  `mkdir -p "#{@destination}/monthly"` if !File.exists?("#{@destination}/monthly")
end

def main()
  sanity_check()
  weekly_backup() if (@day == @end_of_week)
  daily_backup()
  day_of_month = `date +%d`.strip!
  monthly_backup() if (day_of_month == "01")
end

main()
