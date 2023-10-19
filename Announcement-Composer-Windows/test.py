from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
import cryptography.hazmat.primitives.serialization
import json
import requests
import uuid
import datetime
import base64

start = datetime.datetime.now()
end = start + datetime.timedelta(days=7)
id = uuid.uuid4()

keypath = input("Enter the path to the private key: ").strip()
inFile = open(keypath, "rb")
privateKeyFile = inFile.read()
inFile.close()
subject = input("Enter the subject: ").strip()
body = input("Enter the body: ").strip()
scheduleType = input("Enter the schedule type(startOnly, endOnly, startAndEnd): ").strip()

if(scheduleType == "startOnly" or scheduleType == "startAndEnd"):
    startstr = input("Enter Start Date(year-month-day-hour-minute): ")
    startarr = startstr.split("-")
    start = datetime.datetime(int(startarr[0]), int(startarr[1]), int(startarr[2]), int(startarr[3]), int(startarr[4]), 00)
if(scheduleType == "endOnly" or scheduleType == "startAndEnd"):
    endstr = input("Enter End Date(year-month-day-hour-minute): ")
    endarr = endstr.split("-")
    end = datetime.datetime(int(endarr[0]), int(endarr[1]), int(endarr[2]), int(endarr[3]), int(endarr[4]), 00)

#convert time to acceptable format
start = start.replace(microsecond=00)
end = end.replace(microsecond=00)
start = start.isoformat() + "Z"
end = end.isoformat() + "Z"

interruptionLevel = input("Enter the interruption level(passive, active, timeSensitive, critical): ").strip()

announcementDict = {"scheduleType":scheduleType,"subject":subject,"end":end,"interruptionLevel":interruptionLevel,"body":body,"start":start,"id":str(id)}

#converting file to private key object
privateKey = cryptography.hazmat.primitives.serialization.load_ssh_private_key(privateKeyFile, None)

# posts announcements information to server
def submitAnnouncement(announcementDict):
    concat = bytes(announcementDict["subject"] + announcementDict["body"], 'utf-8')
    signedKey = privateKey.sign(concat)
    signature = base64.b64encode(signedKey).decode()
    announcementDict["signature"] = signature
    r = requests.post("https://shuttletracker.app/announcements", data=json.dumps(announcementDict))
    # checks whether signature has been successfully read
    if (r.status_code == 403):
        print("Error Code 403: Signature was rejected, try another signing key.\n")
    elif (r.status_code == 200):
        print("Submission has been accepted.")
    else:
        print(f"Error code {r.status_code}: Aborted due to some unexpected error.")
    return

submitAnnouncement(announcementDict)