'use strict';

const http = require('node:http');

const PLUGIN_NAME = 'homebridge-digital-doorbell-button';
const PLATFORM_NAME = 'DigitalDoorbellBridge';
const DEFAULT_AUTO_OFF_MS = 1000;
const DEFAULT_WEBHOOK_HOST = '0.0.0.0';
const DEFAULT_WEBHOOK_PORT = 51849;
const DEFAULT_WEBHOOK_PATH = '/doorbell/ring';
const SINGLE_PRESS_EVENT = 0;

module.exports = (api) => {
  api.registerPlatform(PLUGIN_NAME, PLATFORM_NAME, DigitalDoorbellPlatform);
};

class DigitalDoorbellPlatform {
  constructor(log, config, api) {
    this.log = log;
    this.config = config || {};
    this.api = api;
    this.bridge = new VirtualDoorbellBridge(this.log, this.api.hap, this.config);
  }

  accessories(callback) {
    this.bridge.startWebhookServer();
    callback([
      this.bridge.createButtonAccessory(),
      this.bridge.createDoorbellAccessory(),
    ]);
  }
}

class VirtualDoorbellBridge {
  constructor(log, hap, config) {
    this.log = log;
    this.hap = hap;
    this.baseName = config.name || 'Digital Doorbell';
    this.buttonName = config.buttonName || `${this.baseName} Button`;
    this.doorbellName = config.doorbellName || `${this.baseName} Doorbell`;
    this.manufacturer = config.manufacturer || 'Custom';
    this.model = config.model || 'Virtual Doorbell Button';
    this.serialBase = config.serialBase || 'digital-doorbell';
    this.autoOffMilliseconds = normalizeAutoOffMilliseconds(config.autoOffMilliseconds);
    this.webhookEnabled = config.webhookEnabled !== false;
    this.webhookHost = normalizeWebhookHost(config.webhookHost);
    this.webhookPort = normalizeWebhookPort(config.webhookPort);
    this.webhookPath = normalizeWebhookPath(config.webhookPath);
    this.buttonAccessory = null;
    this.doorbellAccessory = null;
    this.webhookServer = null;
  }

  createButtonAccessory() {
    this.buttonAccessory = new DigitalDoorbellButtonAccessory({
      log: this.log,
      hap: this.hap,
      name: this.buttonName,
      manufacturer: this.manufacturer,
      model: this.model,
      serialNumber: `${this.serialBase}-button`,
      autoOffMilliseconds: this.autoOffMilliseconds,
      onPress: () => this.triggerDoorbell('Home tile'),
    });
    return this.buttonAccessory;
  }

  createDoorbellAccessory() {
    this.doorbellAccessory = new DigitalDoorbellAccessory({
      log: this.log,
      hap: this.hap,
      name: this.doorbellName,
      manufacturer: this.manufacturer,
      model: this.model,
      serialNumber: `${this.serialBase}-doorbell`,
    });
    return this.doorbellAccessory;
  }

  triggerDoorbell(source) {
    this.log.info('Doorbell triggered by %s', source);
    if (this.doorbellAccessory) {
      this.doorbellAccessory.ring();
    }
  }

  startWebhookServer() {
    if (!this.webhookEnabled || this.webhookServer) {
      return;
    }

    this.webhookServer = http.createServer((request, response) => {
      this.handleWebhookRequest(request, response);
    });

    this.webhookServer.on('error', (error) => {
      this.log.error('Doorbell webhook server error: %s', error.message);
    });

    this.webhookServer.listen(this.webhookPort, this.webhookHost, () => {
      const displayHost = this.webhookHost === '0.0.0.0' ? 'localhost' : this.webhookHost;
      this.log.info(
        'Doorbell webhook listening on http://%s:%s%s',
        displayHost,
        this.webhookPort,
        this.webhookPath,
      );
    });
  }

  handleWebhookRequest(request, response) {
    const requestURL = new URL(request.url || '/', `http://${request.headers.host || 'localhost'}`);
    const isSupportedMethod = request.method === 'POST' || request.method === 'GET';

    if (!isSupportedMethod || requestURL.pathname !== this.webhookPath) {
      respondWithJSON(response, 404, { ok: false, error: 'not_found' });
      return;
    }

    request.on('data', () => {});
    request.on('end', () => {
      const source = request.socket.remoteAddress || 'webhook';
      this.triggerDoorbell(`Webhook ${source}`);
      respondWithJSON(response, 202, {
        ok: true,
        event: 'ring',
        forwardedToHomeKit: true,
      });
    });
  }
}

class DigitalDoorbellButtonAccessory {
  constructor(options) {
    this.log = options.log;
    this.hap = options.hap;
    this.name = options.name;
    this.autoOffMilliseconds = options.autoOffMilliseconds;
    this.onPress = options.onPress;
    this.currentState = false;
    this.autoOffTimer = null;

    const { Service, Characteristic } = this.hap;

    this.informationService = new Service.AccessoryInformation()
      .setCharacteristic(Characteristic.Manufacturer, options.manufacturer)
      .setCharacteristic(Characteristic.Model, options.model)
      .setCharacteristic(Characteristic.SerialNumber, options.serialNumber);

    this.switchService = new Service.Switch(this.name);
    this.switchService.setPrimaryService(true);
    this.switchService
      .getCharacteristic(Characteristic.On)
      .onGet(() => this.currentState)
      .onSet((value) => this.setSwitchState(Boolean(value)));
  }

  identify() {
    this.log.info('Identify requested for %s', this.name);
  }

  getServices() {
    return [this.informationService, this.switchService];
  }

  setSwitchState(nextState) {
    if (!nextState) {
      this.currentState = false;
      this.clearAutoOffTimer();
      return;
    }

    this.currentState = true;
    this.onPress();
    this.armAutoOffTimer();
  }

  armAutoOffTimer() {
    this.clearAutoOffTimer();
    this.autoOffTimer = setTimeout(() => {
      this.currentState = false;
      this.switchService.updateCharacteristic(this.hap.Characteristic.On, false);
    }, this.autoOffMilliseconds);
  }

  clearAutoOffTimer() {
    if (this.autoOffTimer) {
      clearTimeout(this.autoOffTimer);
      this.autoOffTimer = null;
    }
  }
}

class DigitalDoorbellAccessory {
  constructor(options) {
    this.log = options.log;
    this.hap = options.hap;
    this.name = options.name;

    const { Service, Characteristic } = this.hap;

    this.informationService = new Service.AccessoryInformation()
      .setCharacteristic(Characteristic.Manufacturer, options.manufacturer)
      .setCharacteristic(Characteristic.Model, options.model)
      .setCharacteristic(Characteristic.SerialNumber, options.serialNumber);

    this.doorbellService = new Service.Doorbell(this.name);
    this.doorbellService.setPrimaryService(true);

    this.programmableSwitchEvent = this.doorbellService
      .getCharacteristic(Characteristic.ProgrammableSwitchEvent)
      .onGet(() => null);
  }

  identify() {
    this.log.info('Identify requested for %s', this.name);
  }

  getServices() {
    return [this.informationService, this.doorbellService];
  }

  ring() {
    this.programmableSwitchEvent.sendEventNotification(SINGLE_PRESS_EVENT);
  }
}

function normalizeAutoOffMilliseconds(value) {
  const numericValue = Number(value);
  if (!Number.isFinite(numericValue) || numericValue < 100) {
    return DEFAULT_AUTO_OFF_MS;
  }

  return Math.round(numericValue);
}

function normalizeWebhookHost(value) {
  const host = String(value || '').trim();
  return host || DEFAULT_WEBHOOK_HOST;
}

function normalizeWebhookPort(value) {
  const numericValue = Number(value);
  if (!Number.isInteger(numericValue) || numericValue < 1 || numericValue > 65535) {
    return DEFAULT_WEBHOOK_PORT;
  }

  return numericValue;
}

function normalizeWebhookPath(value) {
  const path = String(value || '').trim();
  if (!path) {
    return DEFAULT_WEBHOOK_PATH;
  }

  return path.startsWith('/') ? path : `/${path}`;
}

function respondWithJSON(response, statusCode, payload) {
  response.writeHead(statusCode, { 'Content-Type': 'application/json' });
  response.end(JSON.stringify(payload));
}
