FAKE_GLOBALS = {}

function GlobalsSetValue(key, val)
	FAKE_GLOBALS[key] = tostring(val)	
end

function GlobalsGetValue(key)
	if not FAKE_GLOBALS[key] then return "" end
	return FAKE_GLOBALS[key]
end

require("stringstore")
require("noitaglobalstore")

local test = stringstore.open_store(stringstore.noita.global("ABC"))

local function testval(tab, key, val)
	tab[key] = val
	print("SET: " .. key .. " VAL: " .. tostring(val) .. " TYPE: " .. type(val))
	local retrieved_value = tab[key]
	print("GET: " .. key .. " VAL: " .. tostring(retrieved_value) .. " TYPE: " .. type(retrieved_value))
	print("")
	return retrieved_value
end

testval(test, "a", "b")
testval(test, "num", 123)
testval(test, "num", true)
testval(test, "thisisnil", nil)
local tabtest = testval(test, "x", {})

testval(tabtest, "a", 1)

print(test.x.a)

for k, v in pairs(FAKE_GLOBALS) do
	print(k .. " = " .. tostring(v))
end

ENTITIES = {
	{
		
	}
}

COMPONENTS = {

}

function EntityAddComponent(entity_id, comp_name, table_of_vals)
	table_of_vals.__comp_name = comp_name
	table.insert(COMPONENTS, table_of_vals)
	local component_id = #COMPONENTS
	table.insert(ENTITIES[entity_id], component_id)
	return component_id
end

function ComponentSetValue(component_id, key, val)
	COMPONENTS[component_id][key] = val
end

function ComponentGetValue(component_id, key)
	return COMPONENTS[component_id][key]
end

function EntityGetComponent(entity_id, comp_name)
	local comp_ids = {}
	for i, v in ipairs(ENTITIES[entity_id]) do
		if COMPONENTS[v].__comp_name == comp_name then
			table.insert(comp_ids, v)
		end
	end
	if #comp_ids == 0 then
		return nil
	else
		return comp_ids
	end
end

print("")
print("VariableStorageComponent store:")
print("")
require("noitavariablestore")
local testx = stringstore.open_store(stringstore.noita.variable_storage_components(1))

testx[1] = 3
testx[2] = 2
testx[3] = 1

testx["1"] = "str1"
testx["2"] = "str2"
testx["3"] = "str3"

print("1,2,3 int keys: " .. tostring(testx[1]) .. ", " .. tostring(testx[2]) .. ", " .. tostring(testx[3]))
print("1,2,3 str keys: " .. tostring(testx["1"]) .. ", " .. tostring(testx["2"]) .. ", " .. tostring(testx["3"]))

testx.a = {1, 2, 3}

print(testx.a[1])

print("# of COMPONENTS: " .. tostring(#COMPONENTS))