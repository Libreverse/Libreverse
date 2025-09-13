# frozen_string_literal: true

require 'mkmf'
require 'timeout'

$CXXFLAGS << ' -std=c++17'

# Run a shell command and fail loudly
def sys(cmd)
  puts " -- #{cmd}"
  unless ret = xsystem(cmd)
    raise "ERROR: '#{cmd}' failed"
  end
  ret
end

# CMake runner with timeout so CI doesn’t hang forever
class CMakeTimeout < StandardError; end

def self.run_cmake(timeout, args)
  pid = Process.spawn("cmake #{args}", pgroup: true)
  Timeout.timeout(timeout) { Process.waitpid(pid) }
rescue Timeout::Error
  Process.kill(-9, pid)
  Process.detach(pid)
  raise CMakeTimeout, "cmake has exceeded its timeout of #{timeout}s"
end

MAKE = if Gem.win_platform?
  find_executable('make')
else
  find_executable('gmake') || find_executable('make')
end

abort 'ERROR: GNU make is required to build Google Robotstxt Parser.' unless MAKE

BASE_DIR = File.expand_path(__dir__)
LIBROBOTSTXT_DIR = BASE_DIR

# Require submodules: google/robotstxt (code in robotstxt/) and abseil-cpp (code in abseil-cpp/)
robotstxt_src = File.join(LIBROBOTSTXT_DIR, 'robotstxt')
absl_src = File.join(LIBROBOTSTXT_DIR, 'abseil-cpp')
 unless File.exist?(File.join(robotstxt_src, 'robots.cc')) && File.exist?(File.join(robotstxt_src, 'robots.h'))
   abort "ERROR: Missing google/robotstxt sources at #{robotstxt_src}. Run: git submodule update --init --recursive #{robotstxt_src}"
 end
 unless Dir.exist?(absl_src)
   abort "ERROR: Missing abseil-cpp sources at #{absl_src}. Run: git submodule update --init --recursive #{absl_src}"
 end

LIBDIR = RbConfig::CONFIG['libdir']
INCLUDEDIR = RbConfig::CONFIG['includedir']

HEADER_DIRS = [robotstxt_src, absl_src]

LIB_DIRS = [
  File.join(LIBROBOTSTXT_DIR, 'c-build')
]

Dir.chdir(LIBROBOTSTXT_DIR) do
  # Always start from a clean build tree to avoid stale CMake cache
  if Dir.exist?('c-build')
    require 'fileutils'
    FileUtils.rm_rf('c-build')
  end
  Dir.mkdir('c-build')
  # Seed expected libs layout for abseil to avoid ExternalProject downloads
  libs_dir = File.join('c-build', 'libs')
  Dir.mkdir(libs_dir) unless Dir.exist?(libs_dir)
  absl_src = File.expand_path(File.join('..', 'abseil-cpp'), libs_dir)
  absl_dst = File.join(libs_dir, 'abseil-cpp-src')
  unless File.exist?(absl_dst)
    # Create a symlink abseil-cpp-src -> ../../abseil-cpp so CMake uses local source
    begin
      File.symlink(absl_src, absl_dst)
    rescue Errno::EEXIST
      # ok
    end
  end
  Dir.chdir('c-build') do
    require 'fileutils'
    cm_src_dir = File.join('..', 'cmake-src')
    FileUtils.mkdir_p(cm_src_dir)
    cmakelists = <<~CMAKE
      cmake_minimum_required(VERSION 3.16)
      project(robots LANGUAGES CXX)
      set(CMAKE_CXX_STANDARD 17)
      set(CMAKE_CXX_STANDARD_REQUIRED ON)
      set(CMAKE_CXX_EXTENSIONS OFF)
      set(ABSL_PROPAGATE_CXX_STD ON)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)

      add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../abseil-cpp ${CMAKE_BINARY_DIR}/absl-build EXCLUDE_FROM_ALL)

  add_library(robots SHARED ${CMAKE_CURRENT_SOURCE_DIR}/../robotstxt/robots.cc)
      target_include_directories(robots PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../robotstxt)
      target_link_libraries(robots PRIVATE absl::base absl::strings)
      set_target_properties(robots PROPERTIES OUTPUT_NAME robots)
    CMAKE
    File.write(File.join(cm_src_dir, 'CMakeLists.txt'), cmakelists)

  run_cmake(5 * 60, File.expand_path(cm_src_dir) + ' -DCMAKE_POLICY_VERSION_MINIMUM=3.5')
    sys(MAKE)
  end
end

$LDFLAGS << " -Wl,-rpath,#{File.join(LIBROBOTSTXT_DIR, 'c-build')}"

# Standard mkmf flow
_dir = dir_config('robotstxt', HEADER_DIRS, LIB_DIRS)
# Ensure Abseil headers are discoverable for the wrapper compilation
$INCFLAGS << " -I#{absl_src}"
$CPPFLAGS << " -I#{absl_src}"
$CXXFLAGS << " -I#{absl_src}"
abort 'ERROR: Failed to build robots' unless have_library('robots')

create_makefile('robotstxt')
