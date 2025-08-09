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
			{ key = 'enableCrsDataRemoval', default = false },
			{ key = 'enableSoftwareInfoRemoval', default = false },
			{ key = 'enableLocationInfoRemoval', default = false },
			{ key = 'enableEquipmentInfoRemoval', default = false },
			{ key = 'enableShootingInfoRemoval', default = false },
			{ key = 'enableIptcInfoRemoval', default = false },
		},
	},
	
	LrPluginInfoProvider = 'PluginInfoProvider.lua',
	
	VERSION = { major=1, minor=3, revision=0, build=0 },
}