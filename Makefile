ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>/  devkitpro")
endif

TOPDIR ?= $(CURDIR)

include $(DEVKITPRO)/libnx/switch_rules

TARGET      :=  $(notdir $(CURDIR))
BUILD       :=  build
SOURCES     :=  source
DATA        :=  data
INCLUDES    :=  include
#ROMFS  :=  romfs

ARCH    :=  -march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE

CFLAGS  :=  -g -Wall -O2 -ffunction-sections \
            $(ARCH) $(DEFINES)

CFLAGS  +=  $(INCLUDE) -D__SWITCH__ `sdl2-config --cflags` -I /opt/devkitpro/portlibs/switch/lib -I /opt/devkitpro/libnx/include -I /usr/aarch64-linux-gnu/include 

CXXFLAGS    := $(CFLAGS) -fno-rtti -fno-exceptions

ASFLAGS :=  -g $(ARCH)
LDFLAGS =   -specs=$(DEVKITPRO)/libnx/switch.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS    := -lSDL2 -lnx

LIBDIRS := $(PORTLIBS) $(LIBNX)

ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT   :=  $(CURDIR)/$(TARGET)
export TOPDIR   :=  $(CURDIR)

export VPATH    :=  $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
            $(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR  :=  $(CURDIR)/$(BUILD)

CFILES      :=  $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES    :=  $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES      :=  $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES    :=  $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

ifeq ($(strip $CPPFILES),)
	export LD	:=	$(CC)
else
	export LD	:=	$(CXX)
endif


export OFILES_BIN	:=	$(addsuffix .o,$(BINFILES))
export OFILES_SRC	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES	:=	$(OFILES_BIN) $(OFILES_SRC)
export HFILES_BIN	:=	$(addsuffix .h,$(subst .,_,$(BINFILES)))

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
            $(foreach dir,$(LIBDIRS),-I$(dir)/include) \
            -I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

ifeq ($(strip $(CONFIG_JSON)),)
	jsons := $(wildcard *.json)
	ifneq (,$(findstring $(TARGET).json,$(jsons)))
		export APP_JSON := $(TOPDIR)/$(TARGET).json
	else
		ifneq (,$(findstring config.json,$(jsons)))
			export APP_JSON := $(TOPDIR)/config.json
		endif
	endif
else
	export APP_JSON := $(TOPDIR)/$(CONFIG_JSON)
endif

ifeq ($(strip $(ICON)),)
	icons := $(wildcard *.jpg)
	ifneq (,$(findstring $(TARGET).jpg,$(icons)))
		export APP_ICON := $(TOPDIR)/$(TARGET).jpg
	else
		ifneq (,$(findstring icon.jpg,$(icons)))
			export APP_ICON := $(TOPDIR)/icon.jpg
		endif
	endif
else
	export APP_ICON := $(TOPDIR)/$(ICON)
endif

ifeq ($(strip $(NO_ICON)),)
	export NROFLAGS += --icon=$(APP_ICON)
endif

ifeq ($(strip $(NO_NACP)),)
	export NROFLAGS += --nacp=$(CURDIR)/$(TARGET).nacp
endif

ifneq ($(APP_TITLEID),)
	export NACPFLAGS += --titleid=$(APP_TITLEID)
endif

ifneq ($(ROMFS),)
	export NROFLAGS += --romfsdir=$(CURDIR)/$(ROMFS)
endif



#SDL_CFLAGS = `sdl2-config --cflags`
#SDL_LIBS = `sdl2-config --libs`

#CPPFLAGS += -g -Wall -Wpedantic $(SDL_CFLAGS) $(DEFINES) -MMD

SRCS = andy.cpp benchmark.cpp fileio.cpp fs_posix.cpp game.cpp \
	level1_rock.cpp level2_fort.cpp level3_pwr1.cpp level4_isld.cpp \
	level5_lava.cpp level6_pwr2.cpp level7_lar1.cpp level8_lar2.cpp level9_dark.cpp \
	lzw.cpp main.cpp mdec.cpp menu.cpp mixer.cpp monsters.cpp paf.cpp random.cpp \
	resource.cpp screenshot.cpp sound.cpp staticres.cpp system_sdl2.cpp \
	util.cpp video.cpp

SCALERS := scaler_nearest.cpp scaler_xbr.cpp

OBJS = $(SRCS:.cpp=.o) $(SCALERS:.cpp=.o) 3p/inih/ini.o 3p/libxbr-standalone/xbr.o
DEPS = $(SRCS:.cpp=.d) $(SCALERS:.cpp=.d) build/3p/inih/ini.d build/3p/libxbr-standalone/xbr.d

#all: hode

#hode: $(OBJS)
#	@$(MAKE) --no-print-directory -f $(CURDIR)/Makefile
#
#clean:
#	rm -f $(OBJS) $(DEPS)

#DEPENDS :=  $(OFILES:.o=.d)

.PHONY: $(BUILD) clean all

#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD): $(OBJS)
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
ifeq ($(strip $(APP_JSON)),)
	@rm -fr $(BUILD) $(TARGET).nro $(TARGET).nacp $(TARGET).elf
else
	@rm -fr $(BUILD) $(TARGET).nsp $(TARGET).nso $(TARGET).npdm $(TARGET).elf
endif


#---------------------------------------------------------------------------------
else
.PHONY: all

DEPENDS :=  $(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
ifeq ($(strip $(APP_JSON)),)

all :   $(OUTPUT).nro

ifeq ($(strip $(NO_NACP)),)
$(OUTPUT).nro   :   $(OUTPUT).elf $(OUTPUT).nacp
else
$(OUTPUT).nro   :   $(OUTPUT).elf
endif

else

#else

all :   $(OUTPUT).nsp

$(OUTPUT).nsp   :   $(OUTPUT).nso $(OUTPUT).npdm

$(OUTPUT).nso   :   $(OUTPUT).elf

endif

$(OUTPUT).elf   :   $(OFILES)

$(OFILES_SRC)   : $(HFILES_BIN)

%.bin.o %_bin.h :   %.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

-include $(DEPS)
endif

#@[ -d $@ ] || mkdir -p $@
#$(CXX) $(LDFLAGS) -o $@ $^ $(SDL_LIBS)
