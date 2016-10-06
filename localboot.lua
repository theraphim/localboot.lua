-- localboot.lua - a Lua script for syslinux' lua.c32 comboot module that uses
--                         DMI data to decide between localboot / chainloading
-- Copyright (C) 2015  Martin v. Wittich, IServ GmbH <martin.von.wittich@iserv.eu>
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

-- version 2015-02-19
--
-- syntax check:
--   sudo aptitude install lua5.1
--   luac5.1 localboot.lua && rm -f luac.out && echo "OK"

local dmi = require "dmi"
local syslinux = require "syslinux"
local string = require "string"

function localboot()
  print("localboot.lua: localboot")
  syslinux.local_boot(0)
end

function chain()
  print("localboot.lua: chainloading")
  if (syslinux.derivative() == "PXELINUX") then
    -- PXELINUX; assume the first hard disk is hd0.
    syslinux.run_kernel_image("chain.c32", "hd0", 0, 7)
  else
    -- ISOLINUX/SYSLIUNX; assume we're running from a USB stick hd0, and hd1 is
    -- the first hard disk.
    -- This may not be necessarily correct; ISOLINUX can run both from USB
    -- sticks and CDs, so we can't know for sure whether the first hard disk is
    -- hd0 or hd1. There's no chance to fix this though until we have a disk
    -- API in lua.c32.
    syslinux.run_command("chain.c32 hd1 swap")
  end
end

function trim(s)
  if (s) then
    return string.gsub(s, "^%s*", "")
  end
end

function lower(s)
  if (s) then
    return string.lower(s)
  end
end

if(dmi.supported())
then
  -- DMI supported
  dmitable = dmi.gettable()
  if (dmitable.system) then
    --[[ PXELINUX 6 ]]--
    system_manufacturer = lower(trim(dmitable.system.manufacturer))
    system_version = lower(trim(dmitable.system.version))
    system_product_name = lower(trim(dmitable.system.product_name))
    if (dmitable.base_board) then
      board_manufacturer = lower(trim(dmitable.base_board.manufacturer))
      board_product_name = lower(trim(dmitable.base_board.product_name))
    end
  end

  syst = { 
  ["Acer"] = { "Aspire 3750", "Aspire 3810T",  "Aspire 5820TG", "ASE571/AST671", "Aspire One 753", "AOA150", "Aspire XC600", "Revo 70", "TravelMate 5735Z", "Calpella", "TravelMate 5742", "TravelMate 5744", "TravelMate 5760G", "TravelMate 5760", "TravelMate 8571", "TravelMate P653-M", "AO531h", "Veriton E430G", "Veriton M2610G", "Veriton M290", "Veriton N4620G", "AOD255", "TravelMate 5740", "Veriton L460"},
  ["ASUSTeK Computer INC."] = {"A8N-VM T-System-CSM", "M2N-VM DVI", "M2N-VM SE", "M4N68T-M-LE-V2", "M5A78L-M LX"},
  ["ASUSTeK COMPUTER INC."] = {"H170-PRO", "B85M-E", "B85M-G", "H81M2", "H81M-K"},
  ["ASUS"] = {"H81M-PLUS"},
  ["bluechip Computer AG"] = {"B85M-E"},
  ["Compaq"] = {"Evo D510 SFF"},
  ["Dell Inc."] = {"Latitude E5520", "OptiPlex 3020", "OptiPlex 390", "OptiPlex 790", "OptiPlex 990"},
  ["eMachines"] = {"eMachines E725"},
  ["FUJITSU SIEMENS"] = {"ESPRIMO E", "ESPRIMO Mobile D9510", "ESPRIMO Mobile V5535"},
  ["FUJITSU"] = {"ESPRIMO P5731", "ESPRIMO P910", "ESPRIMO Q510", "LIFEBOOK A512", "LIFEBOOK A530", "LIFEBOOK A531", "LIFEBOOK A532", "LIFEBOOK P702"},
  ["Gigabyte Technology Co., Ltd."] = {"B75M-D3H", "EP31-DS3L", "H81M-D2W"},
  ["Hewlett-Packard"] = {"HP 630 Notebook PC", "HP 635 Notebook PC", "HP 650 Notebook PC", "HP 655 Notebook PC", "Compaq 610", "HP d530 SFF(DC578AV)", "HP d530 SFF(DG781A)", "HP EliteBook 6930p", "HP Pavilion g6 Notebook PC"},
  ["LENOVO"] = {"Lenovo B580", "Lenovo IdeaPad S10-2", "ThinkCentre E73", "ThinkCentre Edge72", "ThinkCentre M57", "ThinkCentre M72e", "ThinkCentre M73", "ThinkCentre M81", "5049", "ThinkCentre M82", "2697", "2697B63", "2929", "ThinkCentre M83", "10AH", "ThinkCentre M92", "ThinkCentre M93", "ThinkCentre M93p", "ThinkPad E520", "ThinkPad T520"},
  ["SAMSUNG ELECTRONICS CO., LTD."]= {"300E4A/300E5A/300E7A/3430EA/3530EA"},
  ["TOSHIBA"] = {"Satellite L300D", "Satellite Pro C660", "SATELLITE PRO C850-1HL", "Satellite Pro C850-1K0"}}



  if (system_manufacturer == lower("innotek GmbH")) then
    if (system_product_name == lower("VirtualBox") and
      string.find(syslinux.version(), "ISOLINUX")) then chain()
    end
  end

  for k, v in pairs(syst) do
    local lk = lower(k)
    if (lk == system_manufacturer or lk == board_manufacturer) then
      for k1, v1 in pairs(v) do
        local lv1 = lower(v1)
        if (lv1 == system_product_name or lv1 == system_version or lv1 == board_product_name) 
          then chain() 
        end
      end
    end
  end

end

localboot()

-- vim: ft=lua

