SOURCES := onion-ubus.sh
DST := onion

all: copy

copy:
	@cp $(SOURCES) $(DST)

clean:
	@rm -rf $(DST)
