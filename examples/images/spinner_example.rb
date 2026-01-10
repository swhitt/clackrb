#!/usr/bin/env ruby
require_relative "../../lib/clack"

spinner = Clack.spinner
spinner.start("Installing dependencies...")
sleep 1.5
spinner.stop("Dependencies installed!")
