return {
	LrSdkVersion = 9.0,
	LrSdkMinimumVersion = 9.0,
	
	LrToolkitIdentifier = 'com.metadata.tuner',
	LrPluginName = LOC "$$$/MetadataAscii/PluginName=Metadata Tuner",
	
	LrExportFilterProvider = {
		title = LOC "$$$/MetadataAscii/ExportFilterProvider/Title=Metadata Tuner",
		file = 'ExportFilterProvider.lua',
		id = 'MetadataTuner',
		exportPresetFields = {
			{ key = 'enableTemplateProcessing', default = false },
			{ key = 'titleTemplate', default = "" },
			{ key = 'captionTemplate', default = "" },
			{ key = 'enableAsciiConversion', default = true },
		},
	},
	
	LrPluginInfoProvider = 'PluginInfoProvider.lua',
	
	VERSION = { major=1, minor=2, revision=0, build=0 },
}
