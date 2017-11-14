#!/usr/bin/python2.7

import os
import sys
import math
import shutil
from datetime import datetime, timedelta


def getScriptPath():
    return os.path.dirname(os.path.realpath(sys.argv[0]))

def totalSecondsTimeDelta(arg):
    return arg.total_seconds()

def totalSecondsDateTime(arg, fixPointInTime):
    return totalSecondsTimeDelta(arg - fixPointInTime)

def timedeltaToString(arg):
    str = "%s" % arg
    if str.endswith(", 0:00:00"):
        str = str.replace(", 0:00:00", "")
    return str

def bytes2human(num):
    for symbol in ['b','KB','MB','GB']:
        if num < 1024.0 and num > -1024.0:
            return "%s%s" % (("%3.1f" % num).rstrip('0').rstrip('.'), symbol)
        num /= 1024.0
    return "%s%s" % (("%3.1f" % num).rstrip('0').rstrip('.'), 'TB')

if __name__ == "__main__":
    # get script path
    workingDir = getScriptPath()
    for arg in sys.argv:
        if arg.startswith("--working-dir="):
            workingDir = arg.replace("--working-dir=", "")

    # get silent property
    verbose = True
    if "--silent" in sys.argv:
        verbose = False

    # get dry run property
    dryRun = True
    if "--no-dry-run" in sys.argv:
        dryRun = False

    # print startup configuration
    if verbose:
        print "Option 'silent' not set, verbose output enabled"
        if dryRun:
            print "Option 'dry run' set, disable with --no-dry-run"
        print "Working directory: %s" % workingDir

    # define a fixed point in time
    fixPointInTime = datetime.today().replace(hour = 0, minute = 0, second = 0, microsecond = 0)

    # build set of nightly builds
    files = []
    for file in os.listdir(workingDir):
        (name, extension) = os.path.splitext(file)
        if extension in [".gz"]:
            absPath = os.path.join(workingDir, file)
            created = datetime.fromtimestamp(os.path.getmtime(absPath))
            size = os.stat(absPath).st_size
            files.append((absPath, file, created, size))
    sortedFiles = sorted(files, key=lambda file: file[2], reverse=True)
    groups = [
        {"min" : timedelta(), "max" : timedelta(days = 7), "modulo" : timedelta(minutes = 1), "files" : [] },
        {"min" : timedelta(days = 7), "max" : timedelta(days = 5*7), "modulo" : timedelta(weeks = 1), "files" : [] },
        {"min" : timedelta(days = 5*7), "max" : timedelta(days = 365), "modulo" : timedelta(days = 20), "files" : [] },
        {"min" : timedelta(days = 365), "max" : timedelta(days = 999999999), "modulo" : timedelta(weeks = 13), "files" : [] }
    ]
    for (absPath, file, created, size) in sortedFiles:
        age = datetime.now() - created
        for group in groups:
            if group["min"] <= age:
                if group["max"] > age:
                    group["files"].append((absPath, file, created, age, size))
    for group in groups:
        # group by modulo
        subGroups = {}
        groupSize = 0
        groupSizeFreed = 0
        for (absPath, file, created, age, size) in group["files"]:
            groupSize += size
            subGroupKey = fixPointInTime + timedelta(seconds=(totalSecondsTimeDelta(group["modulo"]) * math.floor(totalSecondsDateTime(created, fixPointInTime) / totalSecondsTimeDelta(group["modulo"]))))
            if subGroupKey in subGroups:
                subGroups[subGroupKey].append((absPath, file, created, age, size))
            else:
                subGroups[subGroupKey] = [(absPath, file, created, age, size)]
        if verbose:
            print "Age from '%s' to '%s', keeping one file for every '%s'; a total of %s files, consuming %s" % (timedeltaToString(group["min"]), timedeltaToString(group["max"]), timedeltaToString(group["modulo"]), len(group["files"]), bytes2human(groupSize))
        for subGroupKey in sorted(subGroups, reverse=True):
            if verbose:
                print "\t%s" % subGroupKey
            files = subGroups[subGroupKey]
            while len(files) > 1:
                # remove first file in list
                (absPath, file, created, age, size) = files[0]
                if dryRun:
                    if verbose:
                        print "\t\t%s; created=%s; age=%s; size=%s; action=fake delete" % (file, created, age, bytes2human(size))
                else:
                    # shutil.move(absPath, absPath + ".backup")
                    os.remove(absPath)
                    if verbose:
                        print "\t\t%s; created=%s; age=%s; size=%s; action=delete" % (file, created, age, bytes2human(size))
                del files[0]
                groupSizeFreed += size
            # there should be one file left
            (absPath, file, created, age, size) = files[0]
            if verbose:
                print "\t\t%s; created=%s; age=%s, size=%s; action=keep" % (file, created, age, bytes2human(size))
        if groupSizeFreed > 0:
            if verbose:
                print "==> freed about %s" % bytes2human(groupSizeFreed)

