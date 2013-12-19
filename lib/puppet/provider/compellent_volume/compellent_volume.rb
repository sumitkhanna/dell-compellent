require 'puppet/provider/compellent'
require 'puppet/lib/ResponseParser'

Puppet::Type.type(:compellent_volume).provide(:compellent_volume, :parent => Puppet::Provider::Compellent) do
  @doc = "Manage Compellent Volume creation, modification and deletion."
  def createvolume_commandline
    command = "volume create -name '#{@resource[:name]}' -size '#{@resource[:size]}'"
    if #@{resource[:boot]} = "enable"
    command = command + " -boot"
    end

    folder_value = @resource[:volumefolder]
    if "#{folder_value}".size != 0
      command = command + " -folder '#{folder_value}'"
    end

    notes_value = @resource[:notes]
    if "#{notes_value}".size != 0
      command = command + " -notes '#{notes_value}'"
    end

    replayprofile_value = @resource[:replayprofile]
    if "#{replayprofile_value}".size != 0
      command = command + " -replayprofile '#{replayprofile_value}'"
    end

    storageprofile_value = @resource[:storageprofile]
    if "#{storageprofile_value}".size != 0
      command = command + " -storageprofile '#{storageprofile_value}'"
    end
    return command
  end

  def showvolume_commandline
    command = "volume show -name '#{@resource[:name]}'"
    folder_value = @resource[:volumefolder]
    if "#{folder_value}".size != 0
      command = command + " -folder '#{folder_value}'"
    end
    return command
  end

  def get_log_path(num)
    temp_path = Pathname.new(__FILE__).parent
    Puppet.debug("Temp PATH - #{temp_path}")
    $i = 0
    $num = num
    path = Pathname.new(temp_path)
    while $i < $num  do
      path = Pathname.new(temp_path)
      temp_path = path.dirname
      $i +=1
    end
    temp_path = temp_path.join('logs')
    Puppet.debug("Log Path #{temp_path}")
    return  temp_path
  end

  def get_deviceid
    Puppet.debug("Fetching information about the Volume")
    libpath = get_path(2)
    resourcename = @resource[:name]
    vol_show_cli = showvolume_commandline
    volshow_respxml = "#{get_log_path(2)}/volshowResp_#{get_unique_refid}.xml"
    volshow_exitcodexml = "#{get_log_path(2)}/volshowExitCode_#{get_unique_refid}.xml"
    volume_show_command = "java -jar #{libpath} -host #{@resource[:host]} -user #{@resource[:user]} -password #{@resource[:password]} -xmloutputfile #{volshow_exitcodexml} -c \"#{vol_show_cli} -xml #{volshow_respxml}\""
    Puppet.debug(volume_show_command)
    system(volume_show_command)
    Puppet.debug("in method get_deviceid, after exectuing show volume command")
    parser_obj=ResponseParser.new('_')
    folder_value = @resource[:volumefolder]
    if folder_value.length  > 0
	parser_obj.parse_discovery(volshow_exitcodexml,volshow_respxml,0)
	hash= parser_obj.return_response 
    else
	hash = parser_obj.retrieve_empty_folder_volume_properties(volshow_respxml,@resource[:name])
    end
       device_id = "#{hash['volume_DeviceID']}"
    device_id = "#{hash['volume_DeviceID']}"
    return device_id
  end

  def get_unique_refid()
    randno = Random.rand(100000)
    pid = Process.pid
    return "#{randno}_PID_#{pid}"
  end

  def get_path(num)
    temp_path = Pathname.new(__FILE__).parent
    Puppet.debug("Temp PATH - #{temp_path}")
    $i = 0
    $num = num
    path = Pathname.new(temp_path)
    while $i < $num  do
      path = Pathname.new(temp_path)
      temp_path = path.dirname
      $i +=1
    end
    temp_path = temp_path.join('lib/CompCU-6.3.jar')
    Puppet.debug("Path #{temp_path}")
    return  temp_path
  end

  def create

    Puppet.debug("Inside Create Method.")
    libpath = get_path(2)
    folder_value = @resource[:volumefolder]
    host_value = @resource[:host]
    user_value = @resource[:user]
    password_value = @resource[:password]
    resourcename = @resource[:name]
    volume_cli = createvolume_commandline

    volfolder_exitcodexml = "#{get_log_path(2)}/volFolderCreateExitCode_#{get_unique_refid}.xml"

    if "#{folder_value}".size != 0
      Puppet.debug("Creating volume folder with name '#{folder_value}'")
      volume_folder_command = "java -jar #{libpath} -host #{host_value} -user #{user_value} -password #{password_value} -xmloutputfile #{volfolder_exitcodexml} -c \"volumefolder create -name '#{folder_value}'\""
      Puppet.debug(volume_folder_command)
      system (volume_folder_command)
      parser_obj=ResponseParser.new('_')
      parser_obj.parse_exitcode(volfolder_exitcodexml)
      hash= parser_obj.return_response
      if "#{hash['Success']}".to_str() == "TRUE"
        Puppet.debug("Volume folder created successfully.")
      else
        existresult = "#{hash['Error']}".to_str()
        if existresult.include? "already exists"
          Puppet.debug("Volume folder already exists.")
        else
          raise Puppet::Error, "#{hash['Error']}"
        end
      end
    end

    volcreate_exitcodexml = "#{get_log_path(2)}/volCreateExitCode_#{get_unique_refid}.xml"

    volume_create_command = "java -jar #{libpath} -host #{host_value} -user #{user_value} -password #{password_value} -xmloutputfile #{volcreate_exitcodexml} -c \"#{volume_cli}\""
    Puppet.debug(volume_create_command)
    response =  system (volume_create_command)

    parser_obj=ResponseParser.new('_')
    parser_obj.parse_exitcode(volcreate_exitcodexml)
    hash= parser_obj.return_response
    if "#{hash['Success']}".to_str() == "TRUE"
      Puppet.debug("Volume created successfully.")
    else
      raise Puppet::Error, "#{hash['Error']}"
    end
  end

  def destroy
    Puppet.debug("Inside Destroy method")
    libpath = get_path(2)
    resourcename = @resource[:name]
    host_value = @resource[:host]
    user_value = @resource[:user]
    password_value = @resource[:password]
    device_id = get_deviceid
    voldestroy_exitcodexml = "#{get_log_path(2)}/volDestroyExitCode_#{get_unique_refid}.xml"
    if  #{device_id} != ""
    Puppet.debug("Invoking destroy command")
      if #@{resource[:purge]} == "yes"
      volume_destroy_command = "java -jar #{libpath} -host #{host_value} -user #{user_value} -password #{password_value} -xmloutputfile #{voldestroy_exitcodexml} -c \"volume delete -deviceid #{device_id} -purge\""
      else
        volume_destroy_command = "java -jar #{libpath} -host #{host_value} -user #{user_value} -password #{password_value} -xmloutputfile #{voldestroy_exitcodexml} -c \"volume delete -deviceid #{device_id}\""
      end
      Puppet.debug(volume_destroy_command)
      system(volume_destroy_command)
    end
  end

  def exists?
    device_id = get_deviceid
    Puppet.debug("Device Id for Volume - #{device_id}")

    if  "#{device_id}" == ""
      Puppet.debug("Puppet::Volume does not exist")
      false
    else
      Puppet.debug("Puppet::Volume exist")
      true
    end
  end
end

