//
// Created by michael on 24-6-21.
//
#include "test_msg.pb.h"
#include "config.h"
#include <fmt/base.h>
#include <fmt/format.h>
#include <google/protobuf/compiler/importer.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/message.h>

auto ser2string() {
  pb::DataList data_list{};
  data_list.set_uid(100);
  data_list.add_data()->set_id(123);
  data_list.mutable_data(0)->set_value("abc");
  return data_list.SerializeAsString();
}

auto parse_msg_field(const google::protobuf::Message* msg, int recurtion_level) -> void {
  const auto* ref = msg->GetReflection(); // 得到message的反射
  const auto* desp2 = msg->GetDescriptor(); // 得到message的描述器
  auto prefix = std::string("  ", recurtion_level);
  for (int i = 0; i < desp2->field_count(); ++i) {
    auto field = desp2->field(i);
    fmt::print("{}", prefix);
    fmt::print("{}   {}   {}    {}", field->number(), field->type_name(),
               field->cpp_type_name(), field->name());
    if (field->message_type()) {
      // fmt::println("current field is a message type");
    }
    switch (field->cpp_type()) {
      case google::protobuf::FieldDescriptor::CPPTYPE_INT64: {
        fmt::println("   {}", ref->GetInt64(*msg, field));
      }
      break;
      case google::protobuf::FieldDescriptor::CPPTYPE_STRING: {
        fmt::println("   {}", ref->GetString(*msg, field));
      }
      break;
      case google::protobuf::FieldDescriptor::CPPTYPE_UINT64: {
        fmt::println("   {}", ref->GetUInt64(*msg, field));
      }
      break;
      case google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE: {
        fmt::println("");
        if (field->is_repeated()) {
          for (int rid = 0; rid < ref->FieldSize(*msg, field); rid++) {
            parse_msg_field(&ref->GetRepeatedMessage(*msg, field, rid),
                            recurtion_level + 1);
          }
        }
      }
      break;
      default: {
        fmt::print("{}", prefix);
        fmt::println("can't parse type: {} {}", field->type_name(), field->name());
      }
      break;
    }
  }
}

auto get_from_string(std::string data_list_raw_data) {
  google::protobuf::compiler::DiskSourceTree source_tree{};

  // proto文件夹
  source_tree.MapPath(
      "proto",
      PROTO_ROOT_PATH);

  google::protobuf::compiler::Importer importer(&source_tree, nullptr);
  const auto* desp = importer.Import("proto/test_msg.proto"); // 从文件夹导入文件
  const auto* desp_pool = desp->pool(); // 列出文件中所有描述器
  const auto* msg_desp = desp_pool->FindMessageTypeByName("pb.DataList"); // 找到message

  google::protobuf::DynamicMessageFactory factory; // 创建工厂
  auto* msg = factory.GetPrototype(msg_desp)->New(); // 得到目标message然后创建

  msg->ParseFromString(data_list_raw_data); // 解析
  parse_msg_field(msg, 0);
}

int main(int argc, char* argv[]) {
  auto raw_data = ser2string();
  get_from_string(raw_data);
  return 0;
}