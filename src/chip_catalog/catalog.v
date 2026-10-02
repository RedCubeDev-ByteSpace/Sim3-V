module chip_catalog

import os
import net.http.file
import x.json2

pub fn load_catalogs(path string) !(map[string]ChipEntry, map[string][]string) {
	mut catalog := []ChipEntry{}

	// get the filenames of all files in the 'catalogs' directory
	files := os.ls(path)!
	for file in files {
		file_path := os.join_path(path, file)

		// we dont care about directories
		if !os.is_file(file_path) {
			continue
		}

		// only look at .json files
		if os.file_ext(file).to_lower() != '.json' {
			continue
		}

		// if we found a json file
		// -> read it and add it to the catalog
		sub_catalog := load_catalog(file_path) or {
			println("Failed to load catalog file '${file}'!")
			continue
		}
		catalog << sub_catalog

		println("Loaded catalog '${file}'")
	}

	// transfer all chip catalog entries into a map for nicer lookup later on
	mut chips := map[string]ChipEntry{}

	// also create a list of chip groups
	mut groups := map[string][]string{}

	for chip_entry in catalog {
		// make sure theres no duplicates
		if chip_entry.unique_id in chips {
			println("Encountered duplicate unique_id in chip catalog! ('${chips[chip_entry.unique_id].origin_catalog}' and '${chip_entry.origin_catalog}')")
			continue
		}

		// add this chip to the lookup table of all chips
		chips[chip_entry.unique_id] = chip_entry

		// have we met this chips category yet?
		if chip_entry.group !in groups {
			groups[chip_entry.group] = []
		}

		// add this chip to its group
		groups[chip_entry.group] << chip_entry.unique_id
	}

	return chips, groups
}

pub fn load_catalog(path string) ![]ChipEntry {
	// load the files contents
	content := os.read_file(path)!

	// deserialize the json into a list of catalog entries
	mut catalog := json2.decode[[]ChipEntry](content)!

	filename := os.file_name(path)
	for mut entry in catalog {
		// remember where all of these came from for error messages
		entry.origin_catalog = filename

		// also, if theres no group assigned to this, assign a default one
		if entry.group == '' {
			entry.group = 'Kitchen Sink'
		}
	}

	return catalog
}
