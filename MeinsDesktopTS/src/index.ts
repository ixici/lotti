import {app, BrowserWindow} from 'electron'
import * as path from 'path'
import * as electron from 'electron'
import log from 'loglevel'

function createWindow() {
  log.setDefaultLevel('info')
  log.info('App is ready')
  const {width, height} = electron.screen.getPrimaryDisplay().workAreaSize
  const win = new BrowserWindow({
    width: width - 100,
    height: width - 100,
    webPreferences: {
      nodeIntegration: true,
    },
  })

  const indexHTML = path.join(__dirname + '/index.html')
  win.loadFile(indexHTML).then(() => {
    log.info('Main window loaded')
  })
}

app.whenReady().then(createWindow)