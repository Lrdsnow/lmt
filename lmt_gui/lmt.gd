extends Node

# Constants
var LMT_SCRIPT_PATH = "/home/"+OS.get_environment("USER")+"/.lmt/bin/lmt"
var VERBOSE_FLAG = "-v"

# Function to execute the LMT script
func execute_lmt_script(arguments: Array, fix=true):
	var output = []
	OS.execute(LMT_SCRIPT_PATH, arguments, output, true)
	var split_output = []
	if fix:
		for i in output:
			for x in i.split("\n"):
				split_output.append(x)
			split_output.remove_at(len(split_output)-1)
	else: 
		split_output=output
	return split_output

# Function to install packages
func install_packages(packages: Array):
	var arguments = ["install"] + packages
	return execute_lmt_script(arguments)

# Function to update repositories
func update_repositories():
	return execute_lmt_script(["update"])

# Function to print the usage of the LMT script
func print_usage():
	return execute_lmt_script(["-h"])

# Function to get a list of packages
func get_package_list():
	return execute_lmt_script(["-p"])

func get_package_install_status(package) -> bool:
	return true if execute_lmt_script(["-vc", package])[0] == "1" else false

func get_array_from_reposJson(value:String):
	var output_array = []
	for x in execute_lmt_script(["-r", value]):
		output_array.append(x.replace('"', ''))
	return output_array

func get_package_info(package:String):
	var json = JSON.new()
	json.parse(execute_lmt_script(["-n", package], false)[0], true)
	return json.get_data()
