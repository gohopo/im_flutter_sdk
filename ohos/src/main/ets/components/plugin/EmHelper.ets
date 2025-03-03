import { ChatClient, ChatMessage,
  ChatMessageBody,
  ChatMessageReaction,
  ChatMessageReactionChange,
  ChatMessageReactionOperation,
  ChatOptions,
  CmdMessageBody,
  ContentType, Conversation,
  GroupReadAck,
  MessageDirection,
  MessageStatus,
  RecallMessageInfo,
  TextMessageBody } from "@easemob/chatsdk";
import { MethodCall } from "@ohos/flutter_ohos";
import { HashMap } from "@kit.ArkTS";

export default class EmHelper{
  static conversationToJson(conversation: Conversation|null|undefined){
    if(!conversation) return null;
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    try{
      data.set('convId',conversation.conversationId());
      data.set('type',conversation.getType());
      data.set('isPinned',conversation.isPinned());
      data.set('pinnedTime',conversation.getPinnedTime());
      if(conversation.marks()) data.set('marks',conversation.marks().values());
      data.set('ext',JSON.parse(conversation.getExtField()));
    }
    catch(error){}
    return data;
  }
  static getConversationWithParam(call: MethodCall) {
    let convId: string = call.argument('convId');
    let type: number = call.argument('type');
    return ChatClient.getInstance().chatManager()?.getConversation(convId,type,true);
  }
  static getMessageWithParam(call: MethodCall) {
    let messageId: string = call.argument('msg_id');
    return ChatClient.getInstance().chatManager()?.getMessage(messageId);
  }
  static groupReadAckToJson(groupReadAck: GroupReadAck){
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    data.set('msg_id',groupReadAck.getMsgId());
    data.set('ack_id',groupReadAck.getAckId());
    data.set('from',groupReadAck.getFrom());
    data.set('count',groupReadAck.getCount());
    data.set('timestamp',groupReadAck.getTimestamp());
    if(groupReadAck.getContent()) data.set('content',groupReadAck.getContent());
    return data;
  }
  static messageBodyFromJson(type: ContentType,json:HashMap<string,ESObject>){
    if(type==ContentType.TXT){
      let body = new TextMessageBody(json['content']);
      return body;
    }
    else if(type==ContentType.CMD){
      let body = new CmdMessageBody(json['action']);
      return body;
    }
    return null;
  }
  static messageBodyToJson(type: ContentType,messageBody: ChatMessageBody|undefined){
    if(!messageBody) return null;
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    data.set('type',type);
    if(messageBody.operatorId()) data.set('operatorId',messageBody.operatorId());
    if(messageBody.operationTime()) data.set('operatorTime',messageBody.operationTime());
    if(messageBody.operationCount()) data.set('operatorCount',messageBody.operationCount());
    if(type==ContentType.TXT){
      let body = messageBody as TextMessageBody;
      data.set('content',body.getContent());
    }
    else if(type==ContentType.CMD){
      let body = messageBody as CmdMessageBody;
      data.set('action',body.action());
    }
    return data;
  }
  static messageFromParam(call: MethodCall){
    let message: ChatMessage;
    let type: ContentType = call.argument('type');
    let direction: MessageDirection = call.argument('direction');
    if(direction==MessageDirection.SEND){
      message = ChatMessage.createSendMessage(call.argument('to'),EmHelper.messageBodyFromJson(type,call.argument('body')),call.argument('chatType'));
    }
    else{
      message = ChatMessage.createReceiveMessage(call.argument('from'),EmHelper.messageBodyFromJson(type,call.argument('body')),call.argument('chatType'),call.argument('msgId'));
    }
    message.setDirection(direction);
    message.setReceiverRead(call.argument('hasReadAck'));
    if(call.argument('status')==MessageStatus.SUCCESS) message.setUnread(!call.argument('hasRead'));
    message.setIsNeedGroupAck(call.argument('needGroupAck'));
    message.deliverOnlineOnly(call.argument('deliverOnlineOnly'));
    message.setLocalTimestamp(call.argument('localTime'));
    if(call.argument('serverTime')) message.setServerTimestamp(call.argument('serverTime'));
    message.setStatus(call.argument('status'));
    if(call.argument('chatroomMessagePriority')) message.setPriority(call.argument('chatroomMessagePriority'));
    if(call.argument('msgId')) message.setMsgId(call.argument('msgId'));
    if(call.argument('attributes')){
      let attributes: HashMap<string,ESObject> = call.argument('attributes');
      attributes.forEach((value:ESObject,key)=>{
        message.setJsonAttribute(key,value);
      });
    }
    if(call.argument('receiverList')) message.setReceiverList(call.argument('receiverList'));
    return message;
  }
  static messageReactionChangeToJson(change: ChatMessageReactionChange){
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    data.set('conversationId',change.conversationId());
    data.set('messageId',change.messageId());
    data.set('reactions',change.reactions().map((x):HashMap<string,ESObject>=>EmHelper.messageReactionToJson(x)));
    data.set('operations',change.operations().map((x):HashMap<string,ESObject>=>EmHelper.messageReactionOperationToJson(x)));
    return data;
  }
  static messageReactionOperationToJson(operation: ChatMessageReactionOperation){
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    data.set('userId',operation.userId());
    data.set('reaction',operation.reaction());
    data.set('operate',operation.operation());
    return data;
  }
  static messageReactionToJson(reaction: ChatMessageReaction){
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    data.set('reaction',reaction.reaction());
    data.set('count',reaction.userCount());
    data.set('isAddedBySelf',reaction.isAddedBySelf());
    data.set('userList',reaction.userIds());
    return data;
  }
  static messageToJson(message: ChatMessage){
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    data.set('body',EmHelper.messageBodyToJson(message.getType(),message.getBody()));
    data.set('attributes',message.ext());
    data.set('from',message.getFrom());
    data.set('to',message.getTo());
    data.set('hasReadAck', message.isReceiverRead());
    data.set('hasDeliverAck', message.isDelivered());
    data.set('localTime', message.getLocalTimestamp());
    data.set('serverTime', message.getServerTimestamp());
    data.set('status', message.getStatus());
    data.set('chatType', message.getChatType());
    data.set('direction', message.getDirection());
    data.set('conversationId', message.getConversationId());
    data.set('msgId', message.getMsgId());
    data.set('hasRead', !message.isUnread());
    data.set('needGroupAck', message.isNeedGroupAck());
    data.set('onlineState', message.isOnlineState());
    data.set('broadcast', message.isBroadcast());
    return data;
  }
  static optionsWithParam(call: MethodCall) {
    let options = new ChatOptions({
      appId:call.argument('appId'),appKey:call.argument('appKey')
    });
    options.setAutoLogin(call.argument('autoLogin'));
    options.setRequireReadAck(call.argument('requireAck'));
    options.setRequireDeliveryAck(call.argument('requireDeliveryAck'));
    options.setSortMessageByServerTime(call.argument('sortMessageByServerTime'));
    options.setAcceptInvitationAlways(call.argument('acceptInvitationAlways'));
    options.setAutoAcceptGroupInvitations(call.argument('autoAcceptGroupInvitation'));
    options.setDeleteMessagesOnLeaveGroup(call.argument('deleteMessagesAsExitGroup'));
    options.setDeleteMessagesOnLeaveChatroom(call.argument('deleteMessagesAsExitChatRoom'));
    options.setAutoDownloadThumbnail(call.argument('isAutoDownload'));
    options.allowChatroomOwnerLeave(call.argument('isChatRoomOwnerLeaveAllowed'));
    options.setAutoTransferMessageAttachments(call.argument('serverTransfer'));
    options.setAreaCode(call.argument('areaCode'));
    options.setUsingHttpsOnly(call.argument('usingHttpsOnly'));

    options.setEnableTLSConnection(call.argument('enableTLS')??false);
    options.setUseReplacedMessageContents(call.argument('useReplacedMessageContents')??false);
    options.setIncludeSendMessageInMessageListener(call.argument('messagesReceiveCallbackIncludeSend')??false);

    return options;
  }
  static recallMessageToJson(info: RecallMessageInfo){
    let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
    data.set('recallMsgId',info.getRecallMessageId());
    data.set('recallBy',info.getRecallBy());
    if(info.getExt()) data.set('ext',info.getExt());
    if(info.getRecallMessage()) data.set('msg',info.getRecallMessage());
    if(info.getConversationId()) data.set('msg',info.getConversationId());
    return data;
  }
}