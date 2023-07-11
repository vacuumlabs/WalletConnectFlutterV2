import 'package:event/event.dart';
import 'package:logger/logger.dart';
import 'package:walletconnect_flutter_v2/apis/auth_api/auth_engine.dart';
import 'package:walletconnect_flutter_v2/apis/core/relay_client/websocket/http_client.dart';
import 'package:walletconnect_flutter_v2/apis/core/store/generic_store.dart';
import 'package:walletconnect_flutter_v2/apis/core/store/i_generic_store.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/i_sessions.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/sign_engine.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class Web3App implements IWeb3App {
  static const List<List<String>> DEFAULT_METHODS = [
    [
      MethodConstants.WC_SESSION_PROPOSE,
      MethodConstants.WC_SESSION_REQUEST,
    ],
    [
      MethodConstants.WC_AUTH_REQUEST,
    ]
  ];

  bool _initialized = false;

  static Future<Web3App> createInstance({
    required String projectId,
    String relayUrl = WalletConnectConstants.DEFAULT_RELAY_URL,
    required PairingMetadata metadata,
    bool memoryStore = false,
    String extraStoragePrefix = '',
    Level logLevel = Level.nothing,
    HttpWrapper httpClient = const HttpWrapper(),
  }) async {
    final client = Web3App(
      core: Core(
        projectId: projectId,
        relayUrl: relayUrl,
        memoryStore: memoryStore,
        extraStoragePrefix: extraStoragePrefix,
        logLevel: logLevel,
        httpClient: httpClient,
      ),
      metadata: metadata,
    );
    await client.init();

    return client;
  }

  ///---------- GENERIC ----------///

  @override
  final String protocol = 'wc';
  @override
  final int version = 2;

  @override
  final ICore core;
  @override
  final PairingMetadata metadata;

  Web3App({
    required this.core,
    required this.metadata,
  }) {
    signEngine = SignEngine(
      core: core,
      metadata: metadata,
      proposals: GenericStore(
        storage: core.storage,
        context: StoreVersions.CONTEXT_PROPOSALS,
        version: StoreVersions.VERSION_PROPOSALS,
        fromJson: (dynamic value) {
          return ProposalData.fromJson(value);
        },
      ),
      sessions: Sessions(
        storage: core.storage,
        context: StoreVersions.CONTEXT_SESSIONS,
        version: StoreVersions.VERSION_SESSIONS,
        fromJson: (dynamic value) {
          return SessionData.fromJson(value);
        },
      ),
      pendingRequests: GenericStore(
        storage: core.storage,
        context: StoreVersions.CONTEXT_PENDING_REQUESTS,
        version: StoreVersions.VERSION_PENDING_REQUESTS,
        fromJson: (dynamic value) {
          return SessionRequest.fromJson(value);
        },
      ),
    );

    authEngine = AuthEngine(
      core: core,
      metadata: metadata,
      authKeys: GenericStore(
        storage: core.storage,
        context: StoreVersions.CONTEXT_AUTH_KEYS,
        version: StoreVersions.VERSION_AUTH_KEYS,
        fromJson: (dynamic value) {
          return AuthPublicKey.fromJson(value);
        },
      ),
      pairingTopics: GenericStore(
        storage: core.storage,
        context: StoreVersions.CONTEXT_PAIRING_TOPICS,
        version: StoreVersions.VERSION_PAIRING_TOPICS,
        fromJson: (dynamic value) {
          return value;
        },
      ),
      authRequests: GenericStore(
        storage: core.storage,
        context: StoreVersions.CONTEXT_AUTH_REQUESTS,
        version: StoreVersions.VERSION_AUTH_REQUESTS,
        fromJson: (dynamic value) {
          return PendingAuthRequest.fromJson(value);
        },
      ),
      completeRequests: GenericStore(
        storage: core.storage,
        context: StoreVersions.CONTEXT_COMPLETE_REQUESTS,
        version: StoreVersions.VERSION_COMPLETE_REQUESTS,
        fromJson: (dynamic value) {
          return StoredCacao.fromJson(value);
        },
      ),
    );
  }

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    await core.start();
    await signEngine.init();
    await authEngine.init();

    _initialized = true;
  }

  ///---------- SIGN ENGINE ----------///

  @override
  Event<SessionConnect> get onSessionConnect => signEngine.onSessionConnect;
  @override
  Event<SessionEvent> get onSessionEvent => signEngine.onSessionEvent;
  @override
  Event<SessionExpire> get onSessionExpire => signEngine.onSessionExpire;
  @override
  Event<SessionProposalEvent> get onProposalExpire =>
      signEngine.onProposalExpire;
  @override
  Event<SessionExtend> get onSessionExtend => signEngine.onSessionExtend;
  @override
  Event<SessionPing> get onSessionPing => signEngine.onSessionPing;
  @override
  Event<SessionUpdate> get onSessionUpdate => signEngine.onSessionUpdate;
  @override
  Event<SessionDelete> get onSessionDelete => signEngine.onSessionDelete;

  @override
  IGenericStore<ProposalData> get proposals => signEngine.proposals;
  @override
  ISessions get sessions => signEngine.sessions;
  @override
  IGenericStore<SessionRequest> get pendingRequests =>
      signEngine.pendingRequests;

  @override
  late ISignEngine signEngine;

  @override
  Future<ConnectResponse> connect({
    Map<String, RequiredNamespace>? requiredNamespaces,
    Map<String, RequiredNamespace>? optionalNamespaces,
    Map<String, String>? sessionProperties,
    String? pairingTopic,
    List<Relay>? relays,
    List<List<String>>? methods = DEFAULT_METHODS,
  }) async {
    try {
      return await signEngine.connect(
        requiredNamespaces: requiredNamespaces,
        optionalNamespaces: optionalNamespaces,
        sessionProperties: sessionProperties,
        pairingTopic: pairingTopic,
        relays: relays,
        methods: methods,
      );
    } catch (e) {
      // print(e);
      rethrow;
    }
  }

  @override
  Future request({
    required String topic,
    required String chainId,
    required SessionRequestParams request,
  }) async {
    try {
      return await signEngine.request(
        topic: topic,
        chainId: chainId,
        request: request,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  void registerEventHandler({
    required String chainId,
    required String event,
    void Function(String, dynamic)? handler,
  }) {
    try {
      return signEngine.registerEventHandler(
        chainId: chainId,
        event: event,
        handler: handler,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> ping({
    required String topic,
  }) async {
    try {
      return await signEngine.ping(topic: topic);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> disconnectSession({
    required String topic,
    required WalletConnectError reason,
  }) async {
    try {
      return await signEngine.disconnectSession(
        topic: topic,
        reason: reason,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Map<String, SessionData> getActiveSessions() {
    try {
      return signEngine.getActiveSessions();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Map<String, SessionData> getSessionsForPairing({
    required String pairingTopic,
  }) {
    try {
      return signEngine.getSessionsForPairing(
        pairingTopic: pairingTopic,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Map<String, ProposalData> getPendingSessionProposals() {
    try {
      return signEngine.getPendingSessionProposals();
    } catch (e) {
      rethrow;
    }
  }

  @override
  IPairingStore get pairings => core.pairing.getStore();

  ///---------- AUTH ENGINE ----------///
  @override
  Event<AuthResponse> get onAuthResponse => authEngine.onAuthResponse;

  @override
  IGenericStore<AuthPublicKey> get authKeys => authEngine.authKeys;
  @override
  IGenericStore<String> get pairingTopics => authEngine.pairingTopics;
  @override
  IGenericStore<StoredCacao> get completeRequests =>
      authEngine.completeRequests;

  @override
  late IAuthEngine authEngine;

  @override
  Future<AuthRequestResponse> requestAuth({
    required AuthRequestParams params,
    String? pairingTopic,
    List<List<String>>? methods = DEFAULT_METHODS,
  }) async {
    try {
      return authEngine.requestAuth(
        params: params,
        pairingTopic: pairingTopic,
        methods: methods,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Map<int, StoredCacao> getCompletedRequestsForPairing({
    required String pairingTopic,
  }) {
    try {
      return authEngine.getCompletedRequestsForPairing(
        pairingTopic: pairingTopic,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  String formatAuthMessage({
    required String iss,
    required CacaoRequestPayload cacaoPayload,
  }) {
    try {
      return authEngine.formatAuthMessage(
        iss: iss,
        cacaoPayload: cacaoPayload,
      );
    } catch (e) {
      rethrow;
    }
  }
}
