local config = {
    flyPath = '~/bin/fly',
    concourseURL = 'https://concourse.example.com',
    target = 'example',
    pipeline = 'my-pipeline',
    jobs = {
        'deploy-to-test',
        'deploy-to-stage',
        'deploy-to-prod'
    }
}

concourse = hs.menubar.new()
concourse:setTitle('⚪️')

local statusIcon = function()
    output, status, type, rc = hs.execute(config['flyPath']..' -t '..config['target']..' jobs -p '..config['pipeline'])

    if rc ~= 0 then return '⚪️' end
    if string.find(output, 'failed') then return '🔴' end
    if string.find(output, 'started') then return '🏃' end
    return '✅'
end

-- Modified from https://forums.coronalabs.com/topic/29019-convert-string-to-date/?p=156140
local makeTimestamp = function(dateString)
    local pattern = '(%d+)%-(%d+)%-(%d+)@(%d+):(%d+):(%d+)([%+%-])(%d%d)(%d%d)'
    local xyear, xmonth, xday, xhour, xminute, 
        xseconds, xoffset, xoffsethour, xoffsetmin = dateString:match(pattern)
    
    local convertedTimestamp = os.time({year = xyear, month = xmonth, 
        day = xday, hour = xhour, min = xminute, sec = xseconds})
    local offset = xoffsethour * 60
    if xoffset == '-' then offset = offset * -1 end
    return convertedTimestamp + offset
end

-- Modified from https://forum.rainmeter.net/viewtopic.php?t=20034
local formatSeconds = function(secondsArg)
    timeString = ''
    local weeks = math.floor(secondsArg / 604800)
    if weeks > 0 then timeString = timeString..weeks..' weeks, ' end
	local remainder = secondsArg % 604800
    local days = math.floor(remainder / 86400)
    if days > 0 then timeString = timeString..days..' days, ' end
	local remainder = remainder % 86400
    local hours = math.floor(remainder / 3600)
    if hours > 0 then timeString = timeString..hours..' hours, ' end
	local remainder = remainder % 3600
    local minutes = math.floor(remainder / 60)
    if minutes > 0 then timeString = timeString..minutes..' minutes' end
    local seconds = remainder % 60
    	
    return timeString
end

local menu = function()
    local menu = {}

    -- Get the last 1000 builds and split them into a table
    local lastBuilds = hs.execute(config['flyPath']..' -t '..config['target']..' builds -c 1000 --pipeline '..config['pipeline'])
    local builds = {}
    for s in lastBuilds:gmatch('[^\r\n]+') do
        line = {}
        for c in s:gmatch('%S+') do
            table.insert(line, c)
        end
        table.insert(builds, line)
    end

    -- Extract the last succeeded job times as menu items
    for i,job in ipairs(config['jobs']) do
        for j,build in ipairs(builds) do
            if (string.find(build[2]:gsub('%W',''), job:gsub('%W','')) ~= nil and
                string.find(build[4], 'succeeded')) then
                table.insert(menu, {title='Last '..job..': '..formatSeconds(os.difftime(os.time(), makeTimestamp(build[6])))..' ago'})
                break
            end
        end
    end

    table.insert(menu, { title = "-" })
    table.insert(menu, { title = "Open Concourse", fn=function () hs.urlevent.openURL(config['concourseURL']) end })

    return menu
end

concourse:setTitle(statusIcon())
concourse:setMenu(menu())

hs.timer.doEvery(60, function ()
    concourse:setTitle(statusIcon())
    concourse:setMenu(menu())
end)
