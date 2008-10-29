HERE = File.expand_path( File.dirname( __FILE__ ) ).gsub(/\//, '\\')

module RakefileConstants

  PROGRAM_FILES_PATH = ENV['ProgramFiles']
  begin
    Dir.new PROGRAM_FILES_PATH + '\IAR Systems\Embedded Workbench 4.0\arm'
    IAR_ROOT = PROGRAM_FILES_PATH + '\IAR Systems\Embedded Workbench 4.0'
  rescue
    Dir.new PROGRAM_FILES_PATH + '\IAR Systems\Embedded Workbench 4.0 Kickstart\arm'
    IAR_ROOT = PROGRAM_FILES_PATH + '\IAR Systems\Embedded Workbench 4.0 Kickstart'
  end
  
  C_EXTENSION = '.c'
  OBJ_EXTENSION = '.r79'
  BIN_EXTENSION = '.d79'
  
  UNIT_TEST_PATH = 'test'
  UNITY_PATH = '../src'
  SOURCE_PATH = 'src'
  BUILD_PATH = 'build'
  IAR_PATH = IAR_ROOT + '\common'
  IAR_BIN = IAR_PATH + '\bin'
  IAR_INCLUDE = IAR_PATH + '\inc'
  IAR_CORE_PATH = IAR_ROOT + '\arm'
  IAR_CORE_BIN = IAR_CORE_PATH + '\bin'
  IAR_CORE_CONFIG = IAR_CORE_PATH + '\config'
  IAR_CORE_INCLUDE = IAR_CORE_PATH + '\inc'
  IAR_CORE_INCLUDE_DLIB = IAR_CORE_INCLUDE + '\lib'
  IAR_CORE_LIB = IAR_CORE_PATH + '\lib'
  IAR_CORE_DLIB = IAR_CORE_LIB + '\dl5tpannl8n.r79'
  IAR_CORE_DLIB_CONFIG = IAR_CORE_LIB + '\dl5tpannl8n.h'
  IAR_PROCESSOR_SPECIFIC_PATH = HERE + '\proc'
  SIMULATOR_PROCESSOR = IAR_CORE_BIN + '\armproc.dll'
  SIMULATOR_DRIVER = IAR_CORE_BIN + '\armsim.dll'
  SIMULATOR_PLUGIN = IAR_CORE_BIN + '\armbat.dll'
  SIMULATOR_BACKEND_DDF = IAR_CORE_CONFIG + '\ioat91sam9261.ddf'
  PROCESSOR_TYPE = "ARM926EJ-S"
  LINKER_CONFIG = IAR_CORE_CONFIG + '\lnkarm.xcl'
  
  UNITY_SRC = UNITY_PATH + '\unity.c'
  UNITY_HDR = UNITY_PATH + '\unity.h'
  UNITY_OBJ = BUILD_PATH + '\unity' + OBJ_EXTENSION
  UNITY_TEST_OBJ = BUILD_PATH + '\testunity' + OBJ_EXTENSION
  UNITY_TEST_RUNNER_OBJ = BUILD_PATH + '\testunity_Runner' + OBJ_EXTENSION
  UNITY_TEST_EXEC = UNITY_TEST_OBJ.ext BIN_EXTENSION
  TEST_RESULTS = UNITY_TEST_OBJ.ext '.testpass'
  
  COMPILER = IAR_CORE_BIN + '\iccarm.exe'
  LINKER = IAR_BIN + '\xlink.exe'
  SIMULATOR = IAR_BIN + '\CSpyBat.exe'
  
end

module RakefileHelpers
  include RakefileConstants

  def flush_output
    $stderr.flush
    $stdout.flush
  end
  
  def report message
    puts message
    flush_output
  end

  def compile src, obj
    execute "#{COMPILER} --dlib_config \"#{IAR_CORE_DLIB_CONFIG}\" -z3 --no_cse --no_unroll --no_inline --no_code_motion --no_tbaa --no_clustering --no_scheduling --debug --cpu_mode arm --endian little --cpu #{PROCESSOR_TYPE} --stack_align 4 -e --fpu None --diag_suppress Pa050 --diag_suppress Pe111 -I\"#{IAR_CORE_INCLUDE}\" -I\"#{UNITY_PATH}\" -Isrc -Itest #{src} -o#{obj}"
  end

  def link prerequisites, executable
    execute "\"#{LINKER}\" -rt \"#{IAR_CORE_DLIB}\" -B -s __program_start -I\"#{IAR_CORE_CONFIG}\" -I\"#{IAR_CORE_LIB}\" -f \"#{LINKER_CONFIG}\" #{prerequisites.join(' ')} -o #{executable}"
  end

  def run_test executable      
    execute "\"#{SIMULATOR}\" --silent \"#{SIMULATOR_PROCESSOR}\" \"#{SIMULATOR_DRIVER}\" #{executable} --plugin \"#{SIMULATOR_PLUGIN}\" --backend -B --cpu #{PROCESSOR_TYPE} -p \"#{SIMULATOR_BACKEND_DDF}\" -d sim"
  end
  
  def write_result_file filename, results
    if (results.include?("OK\n"))
      output_file = filename.gsub(BIN_EXTENSION, '.testpass')
    else
      output_file = filename.gsub(BIN_EXTENSION, '.testfail')
    end
    File.open(output_file, 'w') do |f|
      f.print results
    end
  end
  
private #####################

  def execute command_string
    report command_string
    output = `#{command_string}`
    report output
    if $?.exitstatus != 0
      raise "Command failed. (Returned #{$?.exitstatus})"
    end
    output
  end

end
