import os
import sys
import cloudflare
import requests
import time

# $0 --help
def print_help():
	print("Usage: python a.py <domain> <subdomain>")
	print("Example: python a.py example.com sub.example.com")
	print("This script updates the DNS record for the given subdomain with the current public IP address.")

# $0 --update-token <token>
def update_token():
	if len(sys.argv) < 3:
		print("Usage: python a.py --update-token <token>")
		exit(1)

	api_token = sys.argv[2]
	with open('token', 'w') as f:
		f.write(api_token)

if len(sys.argv) < 2:
	help()
	exit(0)

opts = {
	'--help': print_help,
	'--update-token': update_token
}

if sys.argv[1] in opts:
	opts[sys.argv[1]]()
	exit(0)

# ================================

with open('token', 'r') as f:
	lines = f.readlines()
	api_token = lines[0].strip()

cf = cloudflare.Cloudflare(api_token=api_token)

zones = cf.zones.list()

zone_id=None
for zone in zones:
	if zone.name==sys.argv[1]:
		zone_id = zone.id

print(zone_id)

records=cf.dns.records.list(
	zone_id=zone_id
).result

record_id=None
for record in records:
	if record.name==sys.argv[2]:
		record_id=record.id

print(record_id)

if record_id is None:
	print("Record not found")
	exit(1)

while True:
	record=cf.dns.records.get(
		dns_record_id=record_id,
		zone_id=zone_id
	)

	try:
		wip = requests.get('https://api.ipify.org').text
	except requests.RequestException as e:
		print(f"Error retrieving public IP address: {e}")

	if record.content != wip:
		print(f"{record.content} != {wip}")
		response=cf.dns.records.edit(
			dns_record_id=record_id,
			zone_id=zone_id,
			content=wip
		)
		print(response)

	time.sleep(60)

