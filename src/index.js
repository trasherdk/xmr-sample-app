/**
 * Sample browser application which uses a JavaScript library to interact
 * with a Monero daemon using RPC and a Monero wallet using RPC and WASM
 * bindings.
 */
require("monero-javascript");

//"use strict"

// detect if called from worker
console.clear();

console.log("ENTER INDEX.JS");
let isWorker = self.document? false : true;
//console.log("IS WORKER: " + isWorker);
if (isWorker) {
  //self.importScripts('monero-javascript-wasm.js');  // TODO: necessary to avoid worker.js onmessage() captured an uncaught exception: ReferenceError: monero_javascript is not defined
  runWorker();
} else {
  runMain();
}

/**
 * Main thread.
 */
async function runMain() {
  console.clear();
  console.log("RUN MAIN");
  
  const revProxy = false;
  // Daemon config
  let protocol = location.protocol.replace(/\:$/,'');
  let daemonHost = location.host.replace(/\/$/,'');
  let daemonPort = revProxy === true ? '/daemon' : protocol === "http" ? ":38081" : ":38081";
//  let daemonRpcUri = `${protocol}://${daemonHost}:${daemonPort}`;
  let daemonRpcUri = `${protocol}://${daemonHost}${daemonPort}`;
  let daemonRpcUsername = "superuser";
  let daemonRpcPassword = "abctesting123";
  console.log("Daemon URI", daemonRpcUri);

  // Wallet config
  let walletPort = revProxy === true ? '/wallet' : protocol === "http" ? ":38083" : ":38083";
//  let walletRpcUri = `${protocol}://${daemonHost}:${walletPort}`;
  let walletRpcUri = `${protocol}://${daemonHost}${walletPort}`;
  let walletRpcUsername = "rpc_user";
  let walletRpcPassword = "abc123";
  let walletRpcFileName = "test_wallet_1";
  let walletRpcFilePassword = "supersecretpassword123";
  console.log("Wallet URI", walletRpcUri);

  let mnemonic = "goblet went maze cylinder stockpile twofold fewest jaded lurk rally espionage grunt aunt puffin kickoff refer shyness tether building eleven lopped dawn tasked toolbox grunt";
  let seedOffset = "";
  let restoreHeight = 531333;
  let proxyToWorker = true;   // proxy core wallet and daemon to worker so main thread is not blocked (recommended)
  let useFS = true;           // optionally save wallets to an in-memory file system, otherwise use empty paths
  let FS = useFS ? require('memfs') : undefined;  // use in-memory file system for demo
  
  // load wasm module on main thread
  console.log("Loading wasm module on main thread...");
  await MoneroUtils.loadKeysModule();
  console.log("done loading module");
  
  // demonstrate c++ utilities which use monero-project via webassembly
  let json = { msg: "This text will be serialized to and from Monero's portable storage format!" };
  let binary = MoneroUtils.jsonToBinary(json);
  assert(binary);
  let json2 = MoneroUtils.binaryToJson(binary);
  assert.deepEqual(json2, json);
  console.log("WASM utils to serialize to/from Monero\'s portable storage format working");
  
  // create a random keys-only wallet
  let walletKeys = await MoneroWalletKeys.createWalletRandom(MoneroNetworkType.STAGENET, "English");
  console.log("Keys-only wallet random mnemonic: " + await walletKeys.getMnemonic());
  
  // connect to monero-daemon-rpc on same thread as core wallet so requests from same client to daemon are synced
  const daemonConfig = {uri: daemonRpcUri, user: daemonRpcUsername, pass: daemonRpcPassword, proxyToWorker: proxyToWorker};
  console.log("Connecting to monero-daemon-rpc" + (proxyToWorker ? " in worker" : ""));
  console.log("Daemon config:", JSON.stringify(daemonConfig));
  let daemon = await MoneroDaemonRpc.create(daemonConfig);
  
  console.log("Daemon RPC: Try to get blockheight..");
  let blockHeight = 0;
  try {
    blockHeight = await daemon.getHeight();
  } catch (e) {
    console.error("Daemon RPC:", e.message);
  }
    
  console.log("Daemon height: " + blockHeight );
  
  // connect to monero-wallet-rpc
  const walletConfig = {uri: walletRpcUri, user: walletRpcUsername, pass: walletRpcPassword};
  console.log("Connecting to monero-wallet-rpc:", JSON.stringify(walletConfig));
  let walletRpc = new MoneroWalletRpc(walletConfig);
  
  // open or create rpc wallet
  try {
    console.log("Attempting to open wallet " + walletRpcFileName + "...");
    await walletRpc.openWallet(walletRpcFileName, walletRpcFilePassword);
  } catch (e) {
        
    // -1 returned when the wallet does not exist or it's open by another application
    if (e.getCode() === -1) {
      console.log("Wallet with name '" + walletRpcFileName + "' not found, restoring from mnemonic");
      
      // create wallet
      await walletRpc.createWalletFromMnemonic(walletRpcFileName, walletRpcFilePassword, mnemonic, restoreHeight);
      await walletRpc.sync();
    } else {
      throw e;
    }
  }
  
  // print wallet rpc balance
  console.log("Wallet rpc mnemonic: " + await walletRpc.getMnemonic());
  console.log("Wallet rpc balance: " + await walletRpc.getBalance());  // TODO: why does this print digits and not object?
  
  // create a core wallet from mnemonic
  console.log("Create connection to daemon:", daemonConfig);
  //let daemonConnection = new MoneroRpcConnection({uri: daemonRpcUri, user: daemonRpcUsername, pass: daemonRpcPassword});
  let daemonConnection = new MoneroRpcConnection(daemonConfig);
  
  let walletCorePath = useFS ? GenUtils.uuidv4() : "";
  console.log("Creating core wallet" + (proxyToWorker ? " in worker" : "") + (useFS ? " at path " + walletCorePath : ""));
  let walletCore = await MoneroWalletCore.createWalletFromMnemonic(walletCorePath, "abctesting123", MoneroNetworkType.STAGENET, mnemonic, daemonConnection, restoreHeight, seedOffset, proxyToWorker, FS); 
  console.log("Core wallet imported mnemonic: " + await walletCore.getMnemonic());
  console.log("Core wallet imported address: " + await walletCore.getPrimaryAddress());
  
  // synchronize core wallet
  console.log("Synchronizing core wallet...");
  let result = await walletCore.sync(new WalletSyncPrinter());  // synchronize and print progress
  console.log("Done synchronizing");
  console.log(result);
  
  // start background syncing with listener
  await walletCore.addListener(new WalletSendReceivePrinter()); // listen for and print send/receive notifications
  await walletCore.startSyncing();                              // synchronize in background
  
  // print balance and number of transactions
  console.log("Core wallet balance: " + await walletCore.getBalance());
  console.log("Core wallet number of txs: " + (await walletCore.getTxs()).length);
  
  // send transaction to self, listener will notify when output is received
  console.log("Sending transaction to self");
  let txSet = await walletCore.send(0, await walletCore.getPrimaryAddress(), new BigInteger("75000000000"));
  console.log("Transaction sent successfully.  Should receive notification soon...");
  console.log("Transaction hash: " + txSet.getTxs()[0].getHash());
  
  console.log("EXIT MAIN");
}

/**
 * Worker thread.
 */
async function runWorker() {
  console.log("RUN INTERNAL WORKER");
  console.log("EXIT INTERNAL WORKER");
}

/**
 * Print sync progress every X blocks.
 */
class WalletSyncPrinter extends MoneroWalletListener {
  
  constructor(blockResolution) {
    super();
    this.blockResolution = blockResolution ? blockResolution : 2500;
  }
  
  onSyncProgress(height, startHeight, endHeight, percentDone, message) {
    if (percentDone === 1 || (startHeight - height) % this.blockResolution === 0) {
      console.log("onSyncProgress(" + height + ", " + startHeight + ", " + endHeight + ", " + percentDone + ", " + message + ")");
    }
  }
}

/**
 * Print sync progress every X blocks.
 */
class WalletSendReceivePrinter extends MoneroWalletListener {
  
  constructor(blockResolution) {
    super();
  }

  onOutputReceived(output) {
    console.log("Wallet received output!");
    console.log(output.toJson());
  }
  
  onOutputSpent(output) {
    console.log("Wallet spent output!");
    console.log(output.toJson());
  }
}