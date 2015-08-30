DST_DIR := rpcd

SOURCES := onion-ubus.sh
DST := onion

all: copy

copy:
	@mkdir -p $(DST_DIR)
	@cp $(SOURCES) $(DST_DIR)/$(DST)

clean:
	@rm -rf $(DST_DIR)
